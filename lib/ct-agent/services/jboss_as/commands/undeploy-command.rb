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

module CoolingTower
  class UndeployCommand
    def initialize( service, options = {})
      @cmds     = {}

      @service        = service
      @state          = @service.state

      @log            = options[:log]             || Logger.new(STDOUT)
      @exec_helper    = options[:exec_helper]     || ExecHelper.new( :log => @log )
      @threaded       = options[:threaded]        || false
    end

    def execute( artifact_id )
      event = @service.db.save_event( :undeploy, :started )

      unless is_valid_artifact_id?( artifact_id )
        msg = "No or invalid artifact_id provided"
        @log.error msg
        @service.db.save_event( :undeploy, :failed, :msg => msg, :parent => event )
        return { :status => 'error', :msg => msg }
      end

      artifact = @service.db.artifact( artifact_id.to_i )

      unless artifact
        msg = "Artifact with id '#{artifact_id}' not found"
        @log.error msg
        @service.db.save_event( :undeploy, :failed, :msg => msg, :parent => event )
        return { :status => 'error', :msg => msg }
      end

      FileUtils.rm( artifact.location, :force => true )

      if @service.db.remove_artifact( artifact_id )
        @service.db.save_event( :undeploy, :finished, :parent => event )
        { :status => 'ok' }
      else
        @service.db.save_event( :undeploy, :failed, :parent => event )
        { :status => 'error', :msg => "Error occurred while removing artifact with id = '#{artifact_id}'" }
      end
    end

    def is_valid_artifact_id?( artifact_id )
      return true if artifact_id.is_a?(Fixnum) or artifact_id.to_s.match(/^\d+$/)
      false
    end
  end
end