#
# Copyright 2010 Red Hat, Inc.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.

require 'sc-agent/services/base-command'
require 'sc-agent/services/jboss_as/commands/update-gossip-host-address-command'
require 'sc-agent/services/jboss_as/commands/update-proxy-list-command'
require 'sc-agent/services/jboss_as/commands/update-s3ping-credentials-command'
require 'sc-agent/services/jboss_as/commands/update-admin-credentials-command'

module SteamCannon
  module JBossAS
    class ConfigureCommand < SteamCannon::BaseCommand
      def initialize( service, options = {})
        super
        @cmds     = {}

        add_command( UpdateGossipHostAddressCommand.new( :log => @log ), :offline )
        add_command( UpdateProxyListCommand.new( :log => @log ), :online )
        add_command( UpdateS3PingCredentialsCommand.new( :log => @log ), :offline )
        add_command( UpdateAdminCredentialsCommand.new( :log => @log, :service => @service ), :offline )
      end

      def add_command( cmd, type )
        @cmds[type] = [] if @cmds[type].nil?
        @cmds[type] << cmd

        self
      end

      def execute( data )
        event = @service.db.save_event( :configure, :started )


        unless [:started, :stopped].include?( @state )
          msg = "Service is currently in '#{@state}' state. It needs to be in 'started' or 'stopped' state to execute this action."
          @log.error msg
          @service.db.save_event( :configure, :failed, :msg => msg )
          raise msg
        end

        invalid_data = true

        begin
          unless data.nil?
            data = JSON.parse( data, :symbolize_names => true )

            invalid_data = false if data.is_a?(Hash)
          end
        rescue
        end

        if invalid_data
          msg = "No or invalid data provided to configure service."
          @log.error msg
          @service.db.save_event( :configure, :failed, :msg => msg )
          raise msg
        end

        @service.state = :configuring

        if @threaded
          Thread.new { configure( data, event ) }
        else
          configure( data, event )
        end

        { :state => @service.state }
      end

      def configure( data, event = nil )
        begin
          restart = false

          gossip_restart = UpdateGossipHostAddressCommand.new( :log => @log ).execute( data[:gossip_host] ) if data[:gossip_host]
          s3_ping_restart = UpdateS3PingCredentialsCommand.new( :log => @log ).execute( data[:s3_ping] ) if data[:s3_ping]
          admin_restart = update_admin_credentials( data[:create_admin] ) if data[:create_admin]

          restart = true if gossip_restart || s3_ping_restart || admin_restart

          substate = @state
          unless data[:proxy_list].nil?
            proxy_command = UpdateProxyListCommand.new(:log => @log, :state => substate)
            proxy_restart = proxy_command.execute( data[:proxy_list] )
            restart = true if restart || proxy_restart
          end

          if restart
            begin
              action = substate == :started ? :restart : :start
              @log.debug "Restarting JBoss AS after configuration with :#{action} action"
              @service.service_helper.execute( action, :event => event, :background => false )
              substate = :started
            rescue
              msg = "Restarting JBoss AS failed, couldn't finish updating JBoss AS"
              @log.error msg
              @service.state = @state
              @service.db.save_event( :configure, :failed, :msg => msg )
              substate = :stopped
              return false
            end
          end

          @service.state = substate
          @service.db.save_event( :configure, :finished )
        rescue => e
          msg = "An error occurred while configuring '#{@service.name}' service: #{e}"
          @log.error e
          @log.error msg
          @service.state = @state
          @service.db.save_event( :configure, :failed, :msg => msg )
          return false
        end
      end

      def update_admin_credentials( credentials )
        UpdateAdminCredentialsCommand.new( :log => @log, :service => @service ).execute( credentials )
      end
    end
  end
end
