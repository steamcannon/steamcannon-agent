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
require 'sc-agent/helpers/client-helper'
require 'logger'
require 'yaml'

module SteamCannon
  class ConfigHelper
    def initialize( options = {} )
      @log            = options[:log]           || Logger.new(STDOUT)

      defaults = {
              'log_level'           => :info,
              'ssl_dir'             => '/etc/steamcannon/agent/ssl',
              'ssl_key_file_name'   => 'private.key',
              'ssl_cert_file_name'  => 'cert.pem'
      }

      @config_location = 'config/agent.yaml'

      # TODO this should be probably removed and a config file used provided by CT with location stored in UserData

      begin
        @config = OpenHash.new(defaults.merge(YAML.load_file( @config_location )))
      rescue
        puts "Could not read config file: '#{@config_location}'."
        exit 1
      end

      # TODO here we need also grab certificates and config location from platform dependent

      detect_platform
    end

    def detect_platform
      @log.info "Discovering platform..."

      platform = nil

      # File.read( "/etc/sysconfig/ct" )


      # TODO remove this!!!
      platform = :ec2

      raise "Unsupported platform!" if platform.nil?

      @log.info "We're on '#{platform}' platform"

      @config.platform = platform
    end

    attr_reader :config
  end
end
