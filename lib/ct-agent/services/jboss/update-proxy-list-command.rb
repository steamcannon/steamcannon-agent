# JBoss, Home of Professional Open Source
# Copyright 2009, Red Hat Middleware LLC, and individual contributors
# by the @authors tag. See the copyright.txt in the distribution for a
# full listing of individual contributors.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
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

module CoolingTower
  class UpdateProxyListCommand
    def initialize( jboss_home, options = {} )
      @jboss_home     = jboss_home

      @log            = options[:log]           || Logger.new(STDOUT)
      @exec_helper    = options[:exec_helper]   || ExecHelper.new( { :log => @log } )

      @default_front_end_port = 80
    end

    # Format:
    #
    #  proxies = { IP_ADDRESS => { host => IP_ADDRESS, :port => PORT } }
    #
    def execute( proxies )
      @log.info "Updating proxy list in JBoss AS..."

      current_proxies = get_current_proxies
      current_hosts = current_proxies.keys

      # first of all, remove old proxies

      current_hosts.each do |host|
        unless proxies.include?(host)
          remove_proxy( host, current_proxies[host][:port] )
        end
      end

      # now we need to add new proxies or update ports
      proxies.keys.each do |host|
        if current_hosts.include?(host)
          unless current_proxies[host][:port].eql?(@default_front_end_port)
            @log.debug "Proxy for host #{current_proxies[host][:host]} needs to be updated because port has changed from #{current_proxies[host][:port]} to #{@default_front_end_port}, updating..."
            remove_proxy( current_proxies[host][:host], current_proxies[host][:port] )
            add_proxy( host, @default_front_end_port )
            @log.debug "Proxy updated."
          end
        else
          @log.debug "Adding new proxy #{host}:#{@default_front_end_port}..."
          add_proxy( host, @default_front_end_port )
          @log.debug "Proxy added."
        end
      end

      @log.info "Proxy list updated"
    end

    def get_current_proxies
      @log.debug "Loading proxy list from JBoss AS..."

      proxy_info  = twiddle_execute( "get jboss.web:service=ModCluster ProxyInfo" ).scan(/\/(\d+\.\d+\.\d+\.\d+):(\d+)=/)
      proxies     = {}

      proxy_info.each do |proxy|
        proxies[proxy[0]] = { :host => proxy[0], :port => proxy[1].to_i }
      end

      @log.debug "Loaded #{proxies.size} proxies."

      proxies
    end

    def add_proxy( host, port )
      @log.debug "Adding new proxy to JBoss AS: #{host}:#{port}..."
      twiddle_execute( "invoke jboss.web:service=ModCluster addProxy #{host} #{port}" )
      @log.debug "Proxy #{host}:#{port} added."
    end

    def remove_proxy( host, port )
      @log.debug "Removing proxy from JBoss AS: #{host}:#{port}..."
      twiddle_execute( "invoke jboss.web:service=ModCluster removeProxy #{host} #{port}" )
      @log.debug "Proxy #{host}:#{port} removed."
    end

    # TODO https://jira.jboss.org/browse/CIRRAS-38
    def twiddle_execute( command )
      @log.debug "Executing '#{command}' using Twiddle..."
      out = @exec_helper.execute("#{@jboss_home}/bin/twiddle.sh -o #{Socket.gethostname} -u admin -p admin #{command}")
      @log.debug "Command executed."
      out
    end
  end
end