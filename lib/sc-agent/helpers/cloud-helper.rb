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

module SteamCannon
  class CloudHelper
    def initialize( options = {} )
      @log            = options[:log]           || Logger.new(STDOUT)
      @client_helper  = options[:client_helper] || ClientHelper.new( :log => @log )
    end

    def discover_platform
      @log.info "Discovering platform..."

      return :ec2 if discover_ec2

      @log.warn "We're on unknown platform!"

      :unknown
    end

    def discover_ec2
      @log.debug "Discovering if we're on EC2..."

      if @client_helper.get('http://169.254.169.254/1.0/meta-data/local-ipv4').nil?
        @log.debug "Nope, it's not EC2."
        false
      else
        true
      end
    end

    def read_certificate( platform )
      case platform
        when :ec2
          begin
            data = JSON.parse( @client_helper.get('http://169.254.169.254/1.0/user-data'), :symbolize_names => true )
            return nil unless data.is_a?(Hash)
            return data[:steamcannon_certificate].nil? ? nil : data[:steamcannon_certificate]  
          rescue => e
            @log.error e
            @log.error "An error occurred while reading UserData."
            return nil
          end
      end
    end
  end
end
