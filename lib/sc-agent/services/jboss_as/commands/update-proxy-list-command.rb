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
require 'resolv'
require  'sc-agent/helpers/exec-helper'
require  'sc-agent/services/jboss_as/jboss-as-service'

module SteamCannon
  class UpdateProxyListCommand

    PROXY_LIST = 'JBOSS_PROXY_LIST'

    def initialize( options = {} )
      @log            = options[:log]           || Logger.new(STDOUT)
      @exec_helper    = options[:exec_helper]   || ExecHelper.new( { :log => @log } )
      @string_helper  = options[:string_helper] || StringHelper.new( { :log => @log } )
      @state          = options[:state]         || :stopped

      @default_front_end_port = 80
    end

    # Format:
    #
    #  proxies = { IP_ADDRESS => { host => IP_ADDRESS, :port => PORT } }
    #
    def execute( proxies )
      return false if proxies.nil?

      @log.info "Updating proxy list in JBoss AS..."

      write_proxy_config(proxies)
      update_running_jboss(proxies) if @state == :started

      @log.info "Proxy list updated"

      # does JBoss AS need to restart?
      @state != :started
    end

    def write_proxy_config(proxies)
      proxy_list = proxies.map do |key, value|
        host = key
        port = value[:port]
        "#{host}:#{port}"
      end
      @log.debug "Reading JBoss AS config file..."
      jboss_config = File.read(JBossASService::JBOSS_AS_SYSCONFIG_FILE)

      @log.info "Writing new proxy list to JBoss AS config file..."
      @string_helper.update_config(jboss_config, PROXY_LIST, proxy_list.join(','))

      File.open(JBossASService::JBOSS_AS_SYSCONFIG_FILE, 'w') {|f| f.write(jboss_config) }
    end

    def update_running_jboss(proxies)
      proxy_hosts = proxies.keys
      current_proxies = get_current_proxies
      current_hosts = current_proxies.keys

      # Convert any hostnames to IPs
      proxy_hosts = proxy_hosts.map { |host| Resolv.getaddress(host) }

      # remove old proxies
      current_hosts.each do |host|
        unless proxy_hosts.include?(host)
          begin
            remove_proxy( host, current_proxies[host][:port] )
          rescue
            # This should not happen
            @log.error "Unable to remove proxy #{host}:#{current_proxies[host][:port]}"
          end
        end
      end

      # now we need to add new proxies or update ports
      proxy_hosts.each do |host|
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
      out = @exec_helper.execute("#{JBossASService::JBOSS_AS_HOME}/bin/twiddle.sh -o #{Socket.gethostname} -u admin -p admin #{command}")
      @log.debug "Command executed."
      out
    end
  end
end
