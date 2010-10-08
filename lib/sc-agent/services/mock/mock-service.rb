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
  class MockService

    def initialize( options = {} )
      @db = ServiceManager.register( self, 'Mock' )

      @log            = options[:log]             || Logger.new(STDOUT)

      # TODO should we also include :error status?
      @state                  = :stopped # available statuses: :starting, :started, :configuring, :stopping, :stopped
    end

    def restart
      unless [:started, :stopped].include?(@state)
        raise "Current service status ('#{@state}') does not allow to restart the service."
      end

      @state = :restarting

      Thread.new do
        sleep 10
        @state = :started
      end

      status
    end

    def start
      unless [:stopped].include?(@state)
        raise "Current service status ('#{@state}') does not allow to start the service."
      end

      @state = :starting

      Thread.new do
        sleep 10
        @state = :started
      end

      status
    end

    def stop
      unless [:started].include?(@state)
        raise "Current service status ('#{@state}') does not allow to stop the service."
      end

      @state = :stopping

      Thread.new do
        sleep 10
        @state = :stopped
      end

      status
    end

    def configure( data )
      unless [:started, :stopped].include?(@state)
        raise "Current service status ('#{@state}') does not allow to configure the service."
      end

      previous_state = @state
      @state = :configuring

      Thread.new do
        sleep 10
        @state = previous_state
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
        raise "Current service status ('#{@state}') does not allow to restart the service."
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

    def tail ( log_id, num_lines, offset )
      offset = (offset || 0).to_i
      lines = num_lines.to_i.times.map { |i| "Line #{i + offset}" }
      { :lines => lines, :offset => offset + 20 }
    end
  end
end
