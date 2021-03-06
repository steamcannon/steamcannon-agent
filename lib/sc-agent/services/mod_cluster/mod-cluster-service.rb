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

require 'sc-agent/services/base-service'
require 'sc-agent/managers/service-manager'
require 'sc-agent/helpers/tail-helper'
require 'json'

module SteamCannon
  class ModClusterService < BaseService

    # TODO: this is currently just a mock driver - it just reports
    # that mod_cluster is :started
    def initialize( options = {} )
      @name = 'mod_cluster'
      @full_name = 'Mod Cluster'
      super
      @state = :started
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
      { :state => :started }
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

    protected
    def tail_command_options
      { :log_dir => "/var/log/httpd" }
    end
  end
end
