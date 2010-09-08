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

require 'openhash/openhash'
require 'logger'
require 'yaml'

module SteamCannon
  class ConfigHelper
    def initialize
      defaults = {
              'environment'               => ENV['RACK_ENV'],
              'log_level'                 => :info,
              'log_dir'                   => '/var/log/steamcannon-agent',
              'ssl_dir'                   => '/var/lib/steamcannon-agent/ssl',
              'ssl_key_file_name'         => 'key.pem',
              'ssl_cert_file_name'        => 'cert.pem',
              'ssl_server_cert_file_name' => 'server_cert.pem'
      }

      @config = OpenHash.new( defaults )

      begin
        agent_config_file = "config/agent-#{@config.environment }.yaml"
        @config.merge!(YAML.load_file( agent_config_file ))
      rescue => e
        puts e
        puts "Could not read config file: '#{agent_config_file}'."
        exit 1
      end    
    end

    attr_reader :config
  end
end
