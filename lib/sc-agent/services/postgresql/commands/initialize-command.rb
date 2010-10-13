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
    class InitializeCommand < BaseCommand

      STORAGE_VOLUME_DEVICE = '/dev/xvdf'
      STORAGE_VOLUME_SLEEP_SECONDS = 10
      STORAGE_VOLUME_MOUNT_POINT = '/data'
      PSQL_DATA_DIR = "#{STORAGE_VOLUME_MOUNT_POINT}/pgsql"
      PSQL_LOG_FILE = "#{STORAGE_VOLUME_MOUNT_POINT}/pgstartup.log"
      PSQL_CONF_FILE = "#{PSQL_DATA_DIR}/pg_hba.conf"
      
      def execute
        event = service.db.save_event( :initialize, :started )

        if @threaded
          Thread.new { initialize_db( event ) }
        else
          initialize_db( event )
        end
      end

      def initialize_db( event = nil )
        log.info "Initializing postgresql db"
        create_postgresql_sysconfig
        initialize_ebs_volume if config.platform == :ec2
        if !File.exists?(PSQL_CONF_FILE)
          initialize_database_config
          update_host_access_permissions
        end
        register_service
        service.start
        service.db.save_event( :initialize, :finished )
      end

      protected
      def create_postgresql_sysconfig
        log.debug "Writing postgresql settings to /etc/sysconfig/pgsql/postgresql"
        @exec_helper.execute("/bin/echo -e 'PGDATA=#{PSQL_DATA_DIR}\nPGLOG=#{PSQL_LOG_FILE}' > /etc/sysconfig/pgsql/postgresql")
      end
      
      def update_host_access_permissions
        log.debug "Updating access permissions in #{PSQL_CONF_FILE}"
        @exec_helper.execute("/bin/sed -i s/'^host'/'# host'/g #{PSQL_CONF_FILE}")
        @exec_helper.execute("/bin/echo 'host    all         all         0.0.0.0/0          md5' >> #{PSQL_CONF_FILE}")
      end

      def initialize_database_config
        log.debug "Initializing postgresql data"
        @exec_helper.execute("/sbin/service postgresql initdb")
      end

      def register_service
        log.debug "Registering postgresql with inetd"
        @exec_helper.execute("/sbin/chkconfig postgresql on")
      end

      def initialize_ebs_volume
        log.debug "Looking for EBS device #{STORAGE_VOLUME_DEVICE}"
        until File.exists?(STORAGE_VOLUME_DEVICE)
          log.debug "#{STORAGE_VOLUME_DEVICE} not found, sleeping #{STORAGE_VOLUME_SLEEP_SECONDS} seconds"
          sleep(STORAGE_VOLUME_SLEEP_SECONDS) 
        end

        begin
          mount_ebs_volume
          log.debug "#{STORAGE_VOLUME_DEVICE} already formatted"
        rescue ExecHelper::ExecError => ex
          if ex.output =~ /you must specify/
            format_ebs_volume
            mount_ebs_volume
          elsif ex.output =~ /already mounted/
            log.debug "#{STORAGE_VOLUME_DEVICE} already mounted at #{STORAGE_VOLUME_MOUNT_POINT}"
          else
            raise ex
          end
        end
      end

      def format_ebs_volume
        log.debug "Formatting #{STORAGE_VOLUME_DEVICE}"
        @exec_helper.execute("yes | mkfs -t ext3 #{STORAGE_VOLUME_DEVICE}")
      end
      
      def mount_ebs_volume
        log.debug "Mounting #{STORAGE_VOLUME_DEVICE} at #{STORAGE_VOLUME_MOUNT_POINT}"
        @exec_helper.execute("mkdir -p #{STORAGE_VOLUME_MOUNT_POINT}")
        @exec_helper.execute("mount #{STORAGE_VOLUME_DEVICE} #{STORAGE_VOLUME_MOUNT_POINT}")
      end
    end
  end
end
