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

require 'logger'
require 'sc-agent/helpers/string-helper'

module SteamCannon
  class UpdateAdminCredentialsCommand

    def initialize(options = {})
      @log             = options[:log]            || Logger.new(STDOUT)
      @service         = options[:service]
      @string_helper   = options[:string_helper]  || StringHelper.new( { :log => @log } )
    end

    def execute(credentials)
      @log.info "Updating admin credentials for JBOSS AS..."

      unless credentials.is_a?(Hash)
        raise "Credentials are in invalid format, got #{credentials.class}, should be a Hash."
      end

      update_jmx_console_credentials(credentials)
    end

    def update_jmx_console_credentials(credentials)
      jmx_console_users_path = config_path("props/jmx-console-users.properties")
      update_credentials(jmx_console_users_path, credentials)
    end

    def config_path(relative_path)
      jboss_conf_dir = "#{JBossASService::JBOSS_AS_HOME}/server/#{@service.jboss_as_configuration}/conf"
      "#{jboss_conf_dir}/#{relative_path}"
    end

    def update_credentials(path, credentials)
      config = File.read(path)
      existing_password = @string_helper.prop_value(config, credentials[:user])
      if existing_password && existing_password == credentials[:password]
        @log.debug "Admin credentials did not change for #{path}"
        false
      else
        write_credentials(path, credentials)
        true
      end
    end

    def write_credentials(path, credentials)
      @log.debug "Writing new admin credentials to #{path}"
      File.open(path, 'w') do |file|
        file.write("#{credentials[:user]}=#{credentials[:password]}")
      end
    end
  end
end
