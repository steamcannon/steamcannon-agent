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

require 'ct-agent/helpers/string-helper'
require 'ct-agent/helpers/client-helper'

module CoolingTower
  class UpdateGossipHostAddressCommand

    JBOSS_GOSSIP_HOST = 'JBOSS_GOSSIP_HOST'

    def initialize( jboss_as_config_file, options = {} )
      @jboss_as_config_file = jboss_as_config_file

      @log              = options[:log]             || Logger.new(STDOUT)
      @string_helper    = options[:string_helper]   || StringHelper.new( { :log => @log } )
      @client_helper    = options[:client_helper]   || ClientHelper.new( { :log => @log } )
    end

    def execute( gossip_host )
      @log.info "Updating JBoss AS GossipRouter Host to '#{gossip_host}'..."

      @jboss_as_config = File.read(@jboss_as_config_file)
      @current_gossip_host = @string_helper.prop_value( @jboss_as_config, gossip_host )

      @log.debug "Current Gossip host value is '#{@current_gossip_host}'" if @current_gossip_host.length > 0

      unless (@current_gossip_host == gossip_host)
        @log.debug "Updating Gossip host to '#{gossip_host}'..."
        @string_helper.update_config( @jboss_as_config, JBOSS_GOSSIP_HOST, gossip_host )
        File.open(@jboss_as_config_file, 'w') {|f| f.write(@jboss_as_config) }
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
