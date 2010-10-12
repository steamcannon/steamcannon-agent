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

require 'sc-agent/services/base-command'

module SteamCannon
  module PostgreSQL
    class ConfigureCommand < BaseCommand

      ALLOWED_COMMANDS = [:create_admin]
      
      def execute( data )
        event = @service.db.save_event( :configure, :started )

        invalid_data = true

        begin
          unless data.nil?
            data = JSON.parse( data, :symbolize_names => true )

            invalid_data = false if data.is_a?(Hash)
          end
        rescue
        end

        if invalid_data
          msg = "No or invalid data provided to configure service."
          @log.error msg
          @service.db.save_event( :configure, :failed, :msg => msg )
          raise msg
        end

        configure( data, event )
      end

      def configure( data, event = nil )
        begin
          command, payload = data.first
          if ALLOWED_COMMANDS.include?(command)
            result = send(command, payload)
          else
            raise "Invalid command :#{command} given"
          end
          @service.db.save_event( :configure, :finished )
          result
        rescue => e
          msg = "An error occurred while configuring '#{@service.name}' service: #{e}"
          @log.error e
          @log.error msg
          @service.db.save_event( :configure, :failed, :msg => msg )
          { :error => msg }
        end
      end

      protected
      def create_admin(data)
        psql("CREATE ROLE #{escape_sql data[:user]} WITH PASSWORD '#{escape_sql data[:password]}' SUPERUSER")
        nil
      end

      def psql(cmd)
        @exec_helper.execute("su postgres -c \"#{cmd}\" | psql")
      end

      def escape_sql(sql)
        sql
      end
    end
  end
end
