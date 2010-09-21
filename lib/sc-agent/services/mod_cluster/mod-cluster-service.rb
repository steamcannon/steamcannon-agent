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

require 'sc-agent/managers/service-manager'
require 'json'

module SteamCannon
  class ModClusterService

    def initialize( options = {} )
      @db    = ServiceManager.register( self, 'mod_cluster' )
      @log   = options[:log] || Logger.new(STDOUT)
      
      # TODO should we also include :error status?
      @state = :stopped # available statuses: :starting, :started, :configuring, :stopping, :stopped
    end

    def restart
      change_state([:started, :stopped], :restarting, :started)
    end

    def start
      change_state([:stopped], :starting, :started)
    end

    def stop
      change_state([:started], :stopping, :stopped)
    end
    
    def configure( data )
      change_state([:started, :stopped], :configuring, @state)
    end

    def change_state(from, interim, final)
      unless from.include?(@state)
        raise "Current service status ('#{@state}') does not allow #{interim} the service."
      end

      @state = interim
      Thread.new do
        sleep 10
        @state = final
      end

      status
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
      unless [:started, :stopped].include?(@state)
        raise "Current service status ('#{@state}') does not allow deploying to the service."
      end

      if a = @db.save_artifact( :name => artifact[:filename], :location => "/opt/mockservice/deploy/#{artifact[:filename]}", :size => artifact[:tempfile].size, :type => artifact[:type] )
        { :artifact_id => a.id }
      else
        raise "Error while saving artifact #{artifact[:filename]}" 
      end
    end

    def undeploy( artifact_id )
      if @db.remove_artifact( artifact_id )
      else
        raise "Error occurred while removing artifact with id = '#{artifact_id}'"
      end
    end
  end
end
