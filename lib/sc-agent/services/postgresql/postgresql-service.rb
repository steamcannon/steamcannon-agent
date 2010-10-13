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
require 'sc-agent/services/postgresql/commands/configure-command'
require 'sc-agent/services/postgresql/commands/initialize-command'
require 'sc-agent/managers/service-manager'
require 'json'

module SteamCannon
  class PostgreSQLService < BaseService

    def initialize(options = {})
      @name = 'postgresql'
      @fullname = @name
      super

      PostgreSQL::InitializeCommand.new(self).execute
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

      super
    end

  end
end
