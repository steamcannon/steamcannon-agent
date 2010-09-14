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
require 'sc-agent/helpers/client-helper'
require 'json'
require 'base64'

module SteamCannon
  class CloudHelper
    VBOX_CONTROL = '/usr/bin/VBoxControl'

    def initialize( options = {} )
      @log            = options[:log]           || Logger.new(STDOUT)
      @client_helper  = options[:client_helper] || ClientHelper.new( :log => @log, :timeout => 1 )
    end

    def discover_platform
      @log.info "Discovering platform..."

      return :ec2 if discover_ec2

      return :virtualbox if discover_virtualbox

      @log.warn "We're on unknown platform!"

      :unknown
    end

    def discover_ec2
      @log.debug "Discovering if we're on EC2..."

      if @client_helper.get('http://169.254.169.254/1.0/meta-data/local-ipv4').nil?
        @log.debug "Nope, it's not EC2."
        false
      else
        @log.debug "Yes, we're on EC2."
        true
      end
    end

    def discover_virtualbox
      @log.debug "Discovering if we're on Virtualbox..."

      if File.exist?(VBOX_CONTROL)
        @log.debug "Yes, we're on Virtualbox."
        true
      else
        @log.debug "Nope, it's not Virtualbox."
        false
      end
    end

    def read_certificate( platform )
      case platform
        when :ec2
          begin
            data = JSON.parse( @client_helper.get('http://169.254.169.254/1.0/user-data'), :symbolize_names => true )
            return nil unless data.is_a?(Hash)
            return data[:steamcannon_ca_cert].nil? ? nil : data[:steamcannon_ca_cert]
          rescue => e
            @log.error e
            @log.error "An error occurred while reading UserData."
            return nil
          end
        when :virtualbox
          begin
            encoded_data = `#{VBOX_CONTROL} guestproperty get /Deltacloud/UserData | grep Value`
            encoded_data.gsub!(/^Value: (.+)/, '\1')
            data = JSON.parse(Base64.decode64(encoded_data), :symbolize_names => true)
            return nil unless data.is_a?(Hash)
            return data[:steamcannon_ca_cert]
          rescue => e
            @log.error e
            @log.error "An error occurred while reading UserData."
            return nil
          end
        else
          @log.warn "!! Unsupported platform: '#{platform}'. I don't know how to load certificate! Returning empty certificate."
          return ""
      end
    end
  end
end
