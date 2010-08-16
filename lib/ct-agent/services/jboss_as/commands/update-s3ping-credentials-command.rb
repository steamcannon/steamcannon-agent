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
  class UpdateS3PingCredentialsCommand

    ACCESS_KEY        = 'JBOSS_JGROUPS_S3_PING_ACCESS_KEY'
    SECRET_ACCESS_KEY = 'JBOSS_JGROUPS_S3_PING_SECRET_ACCESS_KEY'
    BUCKET            = 'JBOSS_JGROUPS_S3_PING_BUCKET'
    LOCATION          = 'JBOSS_JGROUPS_S3_PING_LOCATION'

    def initialize( options = {} )
      @log             = options[:log]            || Logger.new(STDOUT)
      @client_helper   = options[:client_helper]  || ClientHelper.new( { :log => @log } )
      @string_helper   = options[:string_helper]  || StringHelper.new( { :log => @log } )
      @mgmt_address    = options[:mgmt_address]
    end

    def execute( aws_credentials )
      @log.info "Updating AWS credentials for S3_PING..."

      unless aws_credentials.is_a?(Hash)
        raise "Credentials are in invalid format, got #{aws_credentials.class}, should be a Hash."
      end

      @log.debug "Reading JBoss AS config file..."
      @jboss_config = File.read(JBossASService::JBOSS_AS_SYSCONFIG_FILE)

      unless (read_credentials == aws_credentials)
        write_credentials( aws_credentials )

        @log.info "Credentials updated"
        return true
      end

      @log.info "Current and new AWS credentials are same, skipping..."

      false
    end

    def write_credentials( aws_credentials )
      @log.info "Writing new AWS credentials to JBoss AS config file..."

      @string_helper.update_config( @jboss_config, ACCESS_KEY, aws_credentials['access_key'] )
      @string_helper.update_config( @jboss_config, SECRET_ACCESS_KEY, aws_credentials['secret_access_key'] )
      @string_helper.update_config( @jboss_config, BUCKET, aws_credentials['bucket'] )
      @string_helper.update_config( @jboss_config, LOCATION, aws_credentials['location'] )

      @string_helper.add_new_line(@jboss_config)

      File.open(JBossASService::JBOSS_AS_SYSCONFIG_FILE, 'w') {|f| f.write(@jboss_config) }
    end

    def read_credentials
      @log.debug "Reading AWS credentials from config file..."

      credentials = {}

      credentials['access_key']        = @string_helper.prop_value( @jboss_config, ACCESS_KEY )
      credentials['secret_access_key'] = @string_helper.prop_value( @jboss_config, SECRET_ACCESS_KEY )
      credentials['bucket']            = @string_helper.prop_value( @jboss_config, BUCKET )
      credentials['location']          = @string_helper.prop_value( @jboss_config, LOCATION )

      credentials
    end
  end
end
