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

      name = artifact[:filename]

      @log.debug "Received new artifact: #{name}"

      FileUtils.mkdir_p( "#{JBossASService::JBOSS_AS_HOME}/tmp" )

      location        = "#{JBossASService::JBOSS_AS_HOME}/server/#{@service.jboss_as_configuration}/deploy/#{name}"
      tmp_location    = "#{JBossASService::JBOSS_AS_HOME}/tmp/file_#{name}_#{rand(9999999999).to_s.center(10, rand(9).to_s)}"

      if a = @service.db.save_artifact( :name => name, :location => location, :size => artifact[:tempfile].size, :type => artifact[:type] )

        @log.trace "Artifact #{name} saved to DB"

        # First write to tmp location
        File.open( tmp_location, 'w') do |file|
          file.write(artifact[:tempfile].read)
        end

        @log.trace "Artifact #{name} written to a temporary file"

        # Then move the file
        FileUtils.mv( tmp_location, location, :force => true )

        @log.trace "Artifact #{name} deployed."

        @service.db.save_event( :deploy, :finished, :parent => event )
        { :artifact_id => a.id }
      else
        msg = "Error while saving artifact #{name}"
        @service.db.save_event( :deploy, :failed, :parent => event, :msg => msg )
        @log.error msg
        raise msg
      end
    end

    def is_artifact_valid?( artifact )
      return false if artifact.nil? or !artifact.is_a?(Hash) or artifact[:filename].nil? or artifact[:tempfile].nil? or artifact[:type].nil?
      true
    end
  end
end
