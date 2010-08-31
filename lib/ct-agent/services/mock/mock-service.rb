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

require 'ct-agent/managers/service-manager'
require 'json'

module CoolingTower
  class MockService

    def initialize( options = {} )
      @db = ServiceManager.register( self, 'Mock' )

      # TODO should we also include :error status?
      @state                  = :stopped # available statuses: :starting, :started, :configuring, :stopping, :stopped
    end

    def restart
      unless [:started, :stopped].include?(@state)
        msg = "Current service status ('#{@state}') does not allow to restart the service."
        return { :status => 'error', :msg => msg }
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
        msg = "Current service status ('#{@state}') does not allow to start the service."
        return { :status => 'error', :msg => msg }
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
        msg = "Current service status ('#{@state}') does not allow to stop the service."
        return { :status => 'error', :msg => msg }
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
        msg = "Current service status ('#{@state}') does not allow to configure the service."
        return { :status => 'error', :msg => msg }
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
      { :status => 'ok', :response => { :state => @state } }
    end

    def artifact( artifact_id )
      begin
        artifact = @db.artifact( artifact_id.to_i )
      rescue => e
        @log.error e
      end

      unless artifact.nil?
        { :status => 'ok', :response => { :name => artifact.name, :size => artifact.size, :type => artifact.type } }
      else
        msg = "Could not retrieve artifact with id = #{artifact_id}"
        @log.error msg
        { :status => 'error', :msg => msg }
      end
    end

    def artifacts
      artifacts = []

      @db.artifacts.each do |artifact|
        artifacts << { :name => artifact.name, :id => artifact.id }
      end

      { :status => 'ok', :response => artifacts }
    end

    def deploy( artifact )
      unless [:started, :stopped].include?(@state)
        msg = "Current service status ('#{@state}') does not allow to restart the service."
        return { :status => 'error', :msg => msg }
      end

      if a = @db.save_artifact( :name => artifact[:filename], :location => "/opt/mockservice/deploy/#{artifact[:filename]}", :size => artifact[:tempfile].size, :type => artifact[:type] )
        { :status => 'ok', :response => { :artifact_id => a.id } }
      else
        { :status => 'error', :msg => "Error while saving artifact #{artifact[:filename]}" }
      end
    end

    def undeploy( artifact_id )
      if @db.remove_artifact( artifact_id )
        { :status => 'ok' }
      else
        { :status => 'error', :msg => "Error occurred while removing artifact with id = '#{artifact_id}'" }
      end
    end
  end
end
