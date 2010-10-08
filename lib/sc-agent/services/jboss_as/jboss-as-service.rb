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

require 'sc-agent/helpers/service-helper'
require 'sc-agent/services/jboss_as/commands/check-status-command'
require 'sc-agent/services/jboss_as/commands/configure-command'
require 'sc-agent/services/jboss_as/commands/deploy-command'
require 'sc-agent/services/jboss_as/commands/undeploy-command'
require 'sc-agent/services/jboss_as/commands/tail-command'
require 'sc-agent/managers/service-manager'
require 'json'
require 'fileutils'

module SteamCannon
  class JBossASService

    JBOSS_AS_SYSCONFIG_FILE = '/etc/sysconfig/jboss-as'
    JBOSS_AS_HOME           = '/opt/jboss-as'

    attr_accessor :state

    attr_reader :db
    attr_reader :name
    attr_reader :service_helper
    attr_reader :jboss_as_configuration

    def initialize( options = {} )
      @db = ServiceManager.register( self, 'JBoss Application Server' )

      @log            = options[:log]             || Logger.new(STDOUT)
      @exec_helper    = options[:exec_helper]     || ExecHelper.new( :log => @log )

      @service_helper = ServiceHelper.new( self, :log => @log )

      @jboss_as_configuration   = 'cluster-ec2'
      @name                     = 'jboss-as'

      # TODO should we also include :error status?
      @state                  = :stopped # available statuses: :starting, :started, :configuring, :stopping, :stopped
    end

    def restart
      @service_helper.execute( :restart, :backgroud => true )
    end

    def start
      @service_helper.execute( :start, :backgroud => true )
    end

    def stop
      @service_helper.execute( :stop, :backgroud => true )
    end

    def configure( config )
      ConfigureCommand.new( self, :log => @log, :threaded => true  ).execute( config )
    end

    def status
      CheckStatusCommand.new(self, :log => @log).execute
      { :state => @state }
    end

    def artifact( artifact_id )
      begin
        artifact = @db.artifact( artifact_id.to_i )
      rescue => e
        @log.error e
      end

      unless artifact.nil?
        { :name => artifact.name, :size => artifact.size, :type => artifact.type }
      else
        msg = "Could not retrieve artifact with id = #{artifact_id}"
        @log.error msg
        raise msg
      end
    end

    def artifacts
      artifacts = []

      @db.artifacts.each do |artifact|
        artifacts << { :name => artifact.name, :id => artifact.id }
      end

      { :artifacts => artifacts }
    end

    def deploy( artifact )
      DeployCommand.new( self, :log => @log ).execute( artifact )
    end

    def undeploy( artifact_name )
      UndeployCommand.new( self, :log => @log ).execute( artifact_name )
    end

    def deploy_path(name)
      "#{JBOSS_AS_HOME}/server/#{jboss_as_configuration}/deploy/#{name}"
    end

    def logs
      logs = TailCommand.new( self, :log => @log).logs
      { :logs => logs }
    end

    def tail ( log_id, num_lines, offset )
      TailCommand.new( self, :log => @log ).execute( log_id, num_lines, offset )
    end
  end
end
