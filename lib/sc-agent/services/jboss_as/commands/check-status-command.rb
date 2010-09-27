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
require  'sc-agent/helpers/exec-helper'
require  'sc-agent/services/jboss_as/jboss-as-service'

module SteamCannon
  class CheckStatusCommand

    def initialize( service, options = {} )
      @service        = service
      @log            = options[:log]           || Logger.new(STDOUT)
      @exec_helper    = options[:exec_helper]   || ExecHelper.new( { :log => @log } )
    end

    def execute
      @log.info "Checking status of JBoss AS..."
      new_state = nil
      if jboss_as_running?
        @log.info "JBoss AS running"
        new_state = state_transition_map[:running][@service.state]
      else
        @log.info "JBoss AS NOT running"
        new_state = state_transition_map[:not_running][@service.state]
      end
      
      if new_state
        @log.info "Transitioning from :#{@service.state} to :#{new_state}"
        @service.state = new_state
      end
    end

    def state_transition_map
      @state_transition_map ||= {
        :running => {
          :starting => :started,
          :stopped => :started
        },

        :not_running => {
          :started => :stopped,
          :stopping => :stopped
        }
      }
    end

    def jboss_as_running?
      twiddle_execute('jboss.system:type=Server Started') =~ /Started=true/
    end
    
    # TODO https://jira.jboss.org/browse/CIRRAS-38
    # TODO: this should be shared between commands that need it
    # instead of duplicated
    def twiddle_execute( command )
      @log.debug "Executing '#{command}' using Twiddle..."
      out = @exec_helper.execute("#{JBossASService::JBOSS_AS_HOME}/bin/twiddle.sh -o #{Socket.gethostname} -u admin -p admin #{command}")
      @log.debug "Command executed."
      out
    end
  end
end
