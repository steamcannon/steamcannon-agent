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

require 'sc-agent/helpers/tail-command'

module SteamCannon
  class BaseService
    attr_accessor :state

    attr_reader :db
    attr_reader :name
    attr_reader :full_name
    attr_reader :service_helper
    attr_reader :config
    
    def initialize( options = {} )
      @db = ServiceManager.register( self, @name, @full_name )
      
      @log            = options[:log]             || Logger.new(STDOUT)
      @exec_helper    = options[:exec_helper]     || ExecHelper.new( :log => @log )
      @config         = options[:config]
      @service_helper = ServiceHelper.new( self, :log => @log )
      @service_module_name = self.class.name[/(.*)Service/, 1]
        
      # TODO should we also include :error status?
      @state                  = :stopped # available statuses: :starting, :started, :configuring, :stopping, :stopped
    end

    def restart
      @service_helper.execute(:restart, :backgroud => true)
    end

    def start
      @service_helper.execute(:start, :backgroud => true)
    end

    def stop
      @service_helper.execute(:stop, :backgroud => true)
    end

    
    def configure( config )
      eval("#{@service_module_name}::ConfigureCommand").new( self, :log => @log, :threaded => true  ).execute( config )
    end

    def status
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
      eval("#{@service_module_name}::DeployCommand").new( self, :log => @log ).execute( artifact )
    end

    def undeploy( artifact_name )
      eval("#{@service_module_name}::UndeployCommand").new( self, :log => @log ).execute( artifact_name )
    end

    def logs
      { :logs => tail_command ? tail_command.logs : [] }
    end

    def tail( log_id, num_lines, offset )
      tail_command ? tail_command.execute( log_id, num_lines, offset ) : {}
    end

    protected
    def tail_command
      @tail_command ||= tail_command_options ? TailCommand.new(self, { :log => @log }.merge(tail_command_options)) : false
    end

    def tail_command_options
      #override to have log tailing, pointing to the log dir
      # {:log_dir => '/path', :log_file_glob => '*log' } 
    end
  end
end
