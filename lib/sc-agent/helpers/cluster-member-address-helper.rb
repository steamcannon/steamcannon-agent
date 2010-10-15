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

require 'resolv'

module SteamCannon
  class ClusterMemberAddressHelper
    HOSTS_FILE = '/etc/hosts'
    MUTEX = Mutex.new

    def initialize(options = { })
      @log = options[:log] || Logger.new(STDOUT)
    end
    
    def execute(action, *args)
      thread do
        send(action, *args)
      end
      nil
    end

    def create(host, address)
      resolved_address = resolve_address(address)
      if resolved_address
        delete(host)
        @log.debug "Creating entry in #{HOSTS_FILE} for host: #{host} address: #{address} (#{resolved_address})"
        hosts_file('a') do |f|
          f << "#{resolved_address} #{host}\n"
        end
      else
        @log.error "FAILED to create host entry - #{address} did not resolve to an ip address"
      end
    end

    def delete(host)
      @log.debug "Deleting entry (if any) in #{HOSTS_FILE} for #{host}"
      contents = hosts_file.readlines
      hosts_file('w') do |f|
        contents.each do |line|
          f.write("#{line}\n") unless line =~ /\s#{host}$/
        end
      end
    end

    protected
    def thread(&block)
      Thread.new { MUTEX.synchronize(&block) }
    end

    def resolve_address(address)
      Resolv.getaddress(address)
    rescue Resolv::ResolvError => ex
      @log.debug "Resolving #{address} failed: #{ex}"
      nil
    end
    
    def hosts_file(mode = 'r', &block)
      File.open(HOSTS_FILE, mode, &block)
    end
  end
end
