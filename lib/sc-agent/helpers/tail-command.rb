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

require 'pathname'
require 'sc-agent/helpers/tail-helper'

module SteamCannon
  class TailCommand
    def initialize( service, options = {} )
      @service = service
      @log     = options[:log] || Logger.new(STDOUT)
      @log_dir = options[:log_dir]
      @log_file_glob = options[:log_file_glob] || "*log"
    end

    def execute( log_id, num_lines, offset )
      helper = TailHelper.new( log_path(log_id), offset )
      lines = helper.tail( num_lines )
      offset = helper.offset
      { :lines => lines, :offset => offset }
    end

    def logs
      log_path = Pathname.new(@log_dir)
      Dir.glob("#{@log_dir}/**/#{@log_file_glob}").map do |path|
        Pathname.new(path).relative_path_from(log_path).to_s
      end
    end

    def log_path( log_id )
      "#{@log_dir}/#{log_id}"
    end
  end
end
