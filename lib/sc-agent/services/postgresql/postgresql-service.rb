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
require 'json'

module SteamCannon
  class PostgreSQLService < BaseService

    def initialize(options = {})
      @name = 'postgresql'
      @fullname = @name
      super
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

    def configure(data)
      status
    end

    def status
      status_output = @exec_helper.execute("service #{@name} status").match(/(running|stopped)\.*$/)

      @state = :error

      unless status_output.nil?
        case status_output[1]
          when 'running'
            @state = :started
          when 'stopped'
            @state = :stopped
        end
      end

      {:state => @state}
    end

    def artifact(artifact_id)
      begin
        artifact = @db.artifact(artifact_id.to_i)
      rescue => e
        @log.error e
      end

      unless artifact.nil?
        {:name => artifact.name, :size => artifact.size, :type => artifact.type}
      else
        msg = "Could not retrieve artifact with id = #{artifact_id}"
        @log.error msg
        raise msg
      end
    end

    def artifacts
      artifacts = []

      @db.artifacts.each do |artifact|
        artifacts << {:name => artifact.name, :id => artifact.id}
      end

      {:artifacts => artifacts}
    end

    # TODO: dummy output, should be changed in the future
    def deploy(artifact)
      status
    end

    # TODO: dummy output, should be changed in the future
    def undeploy(artifact_id)
      status
    end
  end
end
