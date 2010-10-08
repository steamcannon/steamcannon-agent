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

module SteamCannon
  class TailHelper

    attr_reader :offset

    def initialize(file_path, offset)
      @file_path = file_path
      @offset = (offset || 0).to_i
    end

    def tail(num_lines)
      num_lines = num_lines.to_i
      File.open(@file_path, 'r') do |file|
        if @offset < 0
          file.seek(@offset, IO::SEEK_END)
          file.readline # Advance to the next entire line
        else
          file.seek(@offset)
        end
        lines = (1..num_lines).map do
          begin
            file.readline
          rescue EOFError => e
            nil
          end
        end
        @offset = file.pos
        lines.compact
      end
    end

  end
end
