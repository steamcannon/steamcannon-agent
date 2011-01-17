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
      super

      @jboss_as_configuration = @config.platform == :ec2 ? 'cluster-ec2' : 'cluster'
    end

    def status
      CheckStatusCommand.new(self, :log => @log).execute
      super
    end

    #overrides BaseService#artifact, since we don't store artifacts in
    #the db for jboss
    def artifact( artifact_id )
      if File.exists?(deploy_path(artifact_id))
        { :name => artifact_id, :size => File.size(deploy_path(artifact_id)) }
      else
        msg = "Could not retrieve artifact named '#{artifact_id}'"
        @log.error msg
        raise msg
      end
    end

    def deploy_path(name)
      "#{JBOSS_AS_HOME}/server/#{jboss_as_configuration}/deploy/#{name}"
    end

    def tail_command_options
      { :log_dir => "#{JBossASService::JBOSS_AS_HOME}/server/#{@jboss_as_configuration}/log" }
    end
  end
end
