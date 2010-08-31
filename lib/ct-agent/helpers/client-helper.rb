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

module CoolingTower
  class ClientHelper
    def initialize( options = {} )
      @timeout    = options[:timeout] || 2
      @log        = options[:log]     || Logger.new(STDOUT)
    end

    def get( url )
      @log.debug "GET: #{url}"

      begin
        raw = RestClient.get( url, :timeout => @timeout )

        return raw
      rescue
        return nil
      end
    end

    def put( url, data )
      @log.debug "PUT: #{url}"

      RestClient.put( url, data, :timeout => @timeout )
      return true
    rescue
      return false
    end
  end
end
