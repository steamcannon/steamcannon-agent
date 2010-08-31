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

require 'ct-agent/helpers/string-helper'
require 'ct-agent/helpers/client-helper'

module CoolingTower
  class UpdateGossipHostAddressCommand

    JBOSS_GOSSIP_HOST = 'JBOSS_GOSSIP_HOST'

    def initialize( options = {} )
      @log              = options[:log]             || Logger.new(STDOUT)
      @string_helper    = options[:string_helper]   || StringHelper.new( { :log => @log } )
      @client_helper    = options[:client_helper]   || ClientHelper.new( { :log => @log } )
    end

    def execute( gossip_host )
      @log.info "Updating JBoss AS GossipRouter Host to '#{gossip_host}'..."

      unless gossip_host.is_a?(String)
        raise "Provided Gossip Host address is not valid, got #{gossip_host.class}, should be a String."
      end

      @jboss_as_config = File.read(JBossASService::JBOSS_AS_SYSCONFIG_FILE)
      @current_gossip_host = @string_helper.prop_value( @jboss_as_config, JBOSS_GOSSIP_HOST )

      @log.debug "Current Gossip host value is '#{@current_gossip_host}'" if @current_gossip_host.length > 0

      unless (@current_gossip_host == gossip_host)
        @log.debug "Updating Gossip host to '#{gossip_host}'..."
        @string_helper.update_config( @jboss_as_config, JBOSS_GOSSIP_HOST, gossip_host )
        File.open(JBossASService::JBOSS_AS_SYSCONFIG_FILE, 'w') {|f| f.write(@jboss_as_config) }
        @log.info "GossipRouter Host updated."

        # does it needs JBoss AS restart?
        true
      else
        @log.info "Current and new GossipRouter Host value (#{gossip_host}) is same, skipping..."
        # does it needs JBoss AS restart?
        false
      end
    end
  end
end
