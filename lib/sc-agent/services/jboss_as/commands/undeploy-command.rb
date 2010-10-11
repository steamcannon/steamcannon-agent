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

module SteamCannon
  module JBossAS
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
          msg = "No or invalid artifact id provided"
          @log.error msg
          @service.db.save_event( :undeploy, :failed, :msg => msg, :parent => event )
          raise msg
        end

        artifact_path = @service.deploy_path( artifact_id )

        unless File.exists?(artifact_path)
          msg = "Artifact with id '#{artifact_id}' not found"
          @log.error msg
          @service.db.save_event( :undeploy, :failed, :msg => msg, :parent => event )
          raise msg
        end

        FileUtils.rm( artifact_path, :force => true )

        @service.db.save_event( :undeploy, :finished, :parent => event )

        nil
      end

      def is_valid_artifact_id?( artifact_id )
        return true if artifact_id.to_s.match(/^.*\.war+$/)
        false
      end
    end
  end
end
