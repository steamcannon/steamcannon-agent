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

require 'sc-agent/services/base-service'
require 'sc-agent/helpers/service-helper'
require 'sc-agent/services/jboss_as/commands/check-status-command'
require 'sc-agent/services/jboss_as/commands/configure-command'
require 'sc-agent/services/jboss_as/commands/deploy-command'
require 'sc-agent/services/jboss_as/commands/undeploy-command'
require 'sc-agent/services/jboss_as/commands/tail-command'
require 'sc-agent/managers/service-manager'
require 'json'
require 'fileutils'

module SteamCannon
  class JBossASService < BaseService

    JBOSS_AS_SYSCONFIG_FILE = '/etc/sysconfig/jboss-as'
    JBOSS_AS_HOME           = '/opt/jboss-as'

    attr_reader :jboss_as_configuration

    def initialize( options = {} )
      @name = 'jboss_as'
      @full_name = 'JBoss Application Server'
      @jboss_as_configuration   = 'cluster-ec2'
      super

      #TODO: remove after this happens in the AMI
      unless File.exists?('/etc/init.d/jboss_as')
        @log.info "LINKING /etc/init.d/jboss_as TO /etc/init.d/jboss-as6. SHOULD I STILL BE DOING THIS??"
        @exec_helper.execute("/bin/ln -s /etc/init.d/jboss-as6 /etc/init.d/jboss_as")
      end
    end

    def status
      CheckStatusCommand.new(self, :log => @log).execute
      super
    end

    def deploy_path(name)
      "#{JBOSS_AS_HOME}/server/#{jboss_as_configuration}/deploy/#{name}"
    end

  end
end
