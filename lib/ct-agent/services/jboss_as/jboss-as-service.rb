# JBoss, Home of Professional Open Source
# Copyright 2009, Red Hat Middleware LLC, and individual contributors
# by the @authors tag. See the copyright.txt in the distribution for a
# full listing of individual contributors.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
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

require 'ct-agent/services/jboss_as/commands/update-s3ping-credentials-command'
require 'ct-agent/services/jboss_as/commands/update-gossip-host-address-command'
require 'ct-agent/services/jboss_as/commands/update-proxy-list-command'
require 'ct-agent/managers/service-manager'

module CoolingTower
  class JBossASService

    JBOSS_AS_SYSCONFIG_FILE = '/etc/sysconfig/jboss-as'
    JBOSS_AS_HOME           = '/opt/jboss-as'

    def initialize( options = {} )
      @db = ServiceManager.register( self, 'JBoss Application Server' )

      @log          = options[:log]         || Logger.new(STDOUT)
      @exec_helper  = options[:exec_helper] || ExecHelper.new( :log => @log )

      @jboss_config_file      = '/etc/sysconfig/jboss-as'
      @default_configuration  = 'default'
      @service_name           = 'jboss-as6'

      @status                 = :stopped # available statuses: :starting, :started, :reconfiguring, :stopping, :stopped
    end

    def restart
      @db.save_event( :restart, :received )

      @status = :restarting

      Thread.new do
        manage_service( :restart )
      end

      @log.info "JBoss AS is restarting..."

      { :status => 'ok', :response => { :status => @status } }
    end

    def start
      @db.save_event( :start, :received )

      if @status == :started
        @db.save_event( :start, :finished )
        return { :status => 'ok', :response => { :status => @status } }
      end

      # if is NOT in stopped state
      unless @status == :stopped
        @db.save_event( :start, :failed )
        return { :status => 'error', :msg => "JBoss is currently in '#{@status}' state. It needs to be in 'stopped' state to execute this action." }
      end

      @log.info "Starting JBoss AS..."

      @status = :starting

      Thread.new do
        manage_service( :start )

        @status = :started
        @db.save_event( :start, :finished )
      end

      { :status => 'ok', :response => { :status => @status } }
    end

    def stop
      @db.save_event( :stop, :received )

      Thread.new do
        manage_service( :stop )
      end

      if [:stopped, :stopping].include?( @status )
        return { :status => 'ok', :response => { :status => @status, :call => :ignored } }
      end

      if [ :starting, :reconfiguring ].include?( @status )
        # delay the call?!
        # run in a thread, return current status?

        return { :status => 'ok', :response => { :status => @status, :call => :delayed } }
      end

      @log.info "JBoss AS is stopping..."

      @status = :stopping

      { :status => 'ok', :response => { :status => @status } }
    end

    def status
      { :status => 'ok', :response => { :status => @status } }
    end

    def configure( data )
      @db.save_event( :configure, :received )

      if @status == :reconfiguring
        @db.save_event( :configure, :failed )
        return { :status => 'error', :msg => "Previous reconfiguration still running, please be patient" }
      end

      invalid = true

      begin
        unless data.nil?
          data = JSON.parse( data )

          invalid = false if data.is_a?(Hash)
        end
      rescue
      end

      if invalid
        @db.save_event( :configure, :failed )
        return { :status => 'error', :msg => "No or invalid data specified to configure" }
      end

      status = @status
      @status = :reconfiguring

      @log.info "Reconfiguring JBoss AS..."

      Thread.new do
        begin
          restart = false

          restart = true if UpdateGossipHostAddressCommand.new( :log => @log ).execute( data['gossip_host'] ) unless data['gossip_host'].nil?
          restart = true if UpdateS3PingCredentialsCommand.new( :log => @log ).execute( data['s3_ping'] ) unless data['s3_ping'].nil?

          unless data['proxy_list'].nil?
            if status != :started

              unless manage_service( :start )
                @db.save_event( :configure, :failed )
                Thread.current.exit
              end
            end

            restart = true if UpdateProxyListCommand.new( :log => @log ).execute( data['proxy_list'] ) unless data['proxy_list'].nil?
          end

          @status = status

          if restart
            unless manage_service( :restart )
              @db.save_event( :configure, :failed )
              Thread.current.exit
            end
          end

          @db.save_event( :configure, :finished )
        rescue => e
          @log.error e
          @log.error "An error occurred while updating JBoss configuration."
          @db.save_event( :configure, :failed )
        end
      end

      { :status => 'ok', :response => { :status => @status} }
    end

    def artifacts

      artifacts = []

      @db.artifacts.each do |artifact|
        artifacts << { :name => artifact.name, :id => artifact.id }
      end

      { :status => 'ok', :response => artifacts }
    end

    def deploy( artifact )
      @db.save_event( :deploy, :received )

      #TODO base 64 decode artifact
      # validate the parameter, do the job, etc
      # Tempfile
      # FileUtils.cp( tempfile, "#{JBOSS_AS_HOME}/server/#{@default_configuration}/deploy/" )

      name = 'abc.war'

      if a = @db.save_artifact( :name => name, :location => "#{JBOSS_AS_HOME}/server/#{@default_configuration}/deploy/#{name}" )
        @db.save_event( :deploy, :finished )
        { :status => 'ok', :response => { :artifact_id => a.id } }
      else
        @db.save_event( :deploy, :failed )
        { :status => 'error', :msg => "Error while saving artifact" }
      end
    end

    def undeploy( artifact_id )
      @db.save_event( :undeploy, :received )

      # TODO: remove artifact from JBoss

      if @db.remove_artifact( artifact_id )
        @db.save_event( :undeploy, :finished )
        { :status => 'ok' }
      else
        @db.save_event( :undeploy, :failed )
        { :status => 'error', :msg => "Error occurred while removing artifact with id = '#{artifact_id}'" }
      end
    end

    protected

    def manage_service( operation )
      @log.info "Trying to #{operation} '#{@service_name}' service..."
      begin
        @db.save_event( operation, :received )
        @exec_helper.execute( "service #{@service_name} #{operation}" )
        @db.save_event( operation, :finished )
        @log.info "#{operation} operation executed on service #{@service_name}"
        true
      rescue
        @db.save_event( operation, :failed )
        false
      end
    end
  end
end