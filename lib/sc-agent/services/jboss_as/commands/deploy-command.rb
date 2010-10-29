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

require 'tempfile'
require 'uri'

module SteamCannon
  module JBossAS

    class DeployCommand
      def initialize( service, options = {})
        @cmds     = {}

        @service        = service
        @state          = @service.state

        @log            = options[:log]             || Logger.new(STDOUT)
        @exec_helper    = options[:exec_helper]     || ExecHelper.new( :log => @log )
        @threaded       = options[:threaded]        || false
      end

      def execute( artifact )
        event = @service.db.save_event( :deploy, :started )

        unless [:started, :stopped].include?( @state )
          msg = "Service is currently in '#{@state}' state. It needs to be in 'started' or 'stopped' state to execute this action."
          @log.error msg
          @service.db.save_event( :deploy, :failed, :msg => msg, :parent => event )
          raise msg
        end

        unless is_artifact_valid?( artifact )
          msg = "No or invalid artifact provided"
          @log.error msg
          @service.db.save_event( :deploy, :failed, :msg => msg, :parent => event )
          raise msg
        end

        if is_artifact_pull_url?(artifact)
          @log.debug "Pulling artifact"
          status = :pending
          Thread.new {
            artifact = pull_artifact(artifact)
            write_and_move_artifact(artifact)
            @service.db.save_event( :deploy, :finished, :parent => event )
          }
        else
          status = :deployed
          write_and_move_artifact(artifact)
          @service.db.save_event( :deploy, :finished, :parent => event )
        end

        { :status => status }
      end

      def is_artifact_valid?( artifact )
        is_artifact_file_push?(artifact) or is_artifact_pull_url?(artifact)
      end

      def is_artifact_file_push?(artifact)
        return false if artifact.nil? or !artifact.is_a?(Hash) or artifact[:filename].nil? or artifact[:tempfile].nil? or artifact[:type].nil?
        true
      end

      def is_artifact_pull_url?(artifact)
        !artifact_location(artifact).nil?
      end

      def artifact_location(artifact)
        location = nil
        unless artifact.nil? or artifact.is_a?(Hash)
          begin
            json = JSON.parse(artifact, :symbolize_names => true)
            location = json[:location]
          rescue JSON::ParserError
            # ignore invalid json
          end
        end
        location
      end

      def pull_artifact(artifact)
        tempfile = Tempfile.new('artifact')
        location = artifact_location(artifact)
        filename = URI.parse(location).path.split("/").last
        `curl "#{location}" > #{tempfile.path}`
        { :filename => filename,
          :tempfile => tempfile
        }
      end

      def write_and_move_artifact(artifact)
        name = artifact[:filename]

        @log.debug "Received new artifact: #{name}"

        FileUtils.mkdir_p( "#{JBossASService::JBOSS_AS_HOME}/tmp" )

        location        = @service.deploy_path(name)
        tmp_location    = "#{JBossASService::JBOSS_AS_HOME}/tmp/file_#{name}_#{rand(9999999999).to_s.center(10, rand(9).to_s)}"


        # First write to tmp location
        `cp "#{artifact[:tempfile].path}" "#{tmp_location}"`
        `chmod 644 "#{tmp_location}"`
        @log.trace "Artifact #{name} written to a temporary file"

        begin
          # Then move the file
          FileUtils.mv( tmp_location, location )
        rescue => e
          @log.error e.backtrace
          raise "Artifact couldn't be deployed."
        end

        @log.trace "Artifact #{name} deployed."


      end
    end
  end
end
