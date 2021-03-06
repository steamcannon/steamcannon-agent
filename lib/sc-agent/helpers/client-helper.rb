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

require 'rubygems'
require 'restclient'
require 'logger'

module SteamCannon
  class ClientHelper
    def initialize( options = {} )
      @timeout    = options[:timeout] || 2
      @log        = options[:log]     || Logger.new(STDOUT)
    end

    def get( url )
      @log.trace "GET: #{url}"

      begin
        raw = RestClient::Resource.new( url, :timeout => @timeout ).get
        @log.debug "GET response: #{raw.to_s[0, 50]}"
        return raw
      rescue Exception => ex
        @log.error "GET failed: #{ex.message}"
        @log.error ex.backtrace.join("\n")
        return nil
      end
    end

    def put( url, data )
      @log.trace "PUT: #{url}"

      RestClient::Resource.new( url, data, :timeout => @timeout ).put
      return true
    rescue Exception => ex
      @log.error "PUT failed: #{ex.message}"
      @log.error ex.backtrace.join("\n")
      return false
    end
  end
end
