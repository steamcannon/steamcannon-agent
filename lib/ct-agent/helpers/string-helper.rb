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

module CoolingTower
  class StringHelper
    def initialize( options = {} )
      @log = options[:log] || Logger.new(STDOUT)
    end

    def update_config( string, name, value )
      if string.scan(/^#{name}=(.*)$/).size == 0
        string << (is_last_line_empty?(string) ? "#{name}=#{value}" : "\n#{name}=#{value}")
      else
        string.gsub!( /^#{name}=(.*)$/, "#{name}=#{value}" )
      end
    end

    def prop_value( string, name )
      string.scan(/^#{name}=(.*)/).to_s
    end

    def is_last_line_empty?( string )
      string.match(/^(.*)$\z/).nil? ? true : false
    end

    def add_new_line( string )
      string << "\n" unless is_last_line_empty?( string )
    end

  end
end