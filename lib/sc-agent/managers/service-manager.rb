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

require 'sc-agent/helpers/config-helper'
require 'sc-agent/helpers/log-helper'
require 'sc-agent/helpers/db-helper'
require 'sc-agent/helpers/ssl-helper'

module SteamCannon
  class ServiceManager
    class << self
      attr_accessor :services

      def prepare( config, log )
        @config  = config
        @log     = log

        @services = {}

        Dir.glob("lib/sc-agent/services/**/*-service.rb").each  do |file|
          require file.match(/^lib\/(.*)\.rb$/)[1]
        end

        self
      end

      def configure( cert, keypair )
        @log.info "Reconfiguring Agent..."

        ssl_helper = SSLHelper.new( @config, :log => @log )

        @log.debug  "Saving received certificates..."

        ssl_helper.store_cert_file( cert )
        ssl_helper.store_key_file( keypair )

        @log.info "Executing service restart..."
        child = fork do
          ExecHelper.new( :log => @log ).execute('service steamcannon-agent restart')
        end
        Process.detach(child)
        exit!(0)
      end

      def load_services
        @log.info "Loading services..."

        @config['services'].each do |service_name|
          @log.trace "Loading #{service_name} service..."
          eval("SteamCannon::#{service_name}Service").new( :log => @log, :config => @config )
          @log.trace "Service #{service_name} loaded."
        end unless @config['services'].nil?

        @log.info "#{@config['services'].size} service(s) loaded."
      end

      def register( o, full_name )
        @log.trace "Registering #{o.class} service..."

        name = underscore(o.class.name.split('::').last.split('Service').first)

        @services[name] = { :object => o, :info => { :name => name, :full_name => full_name } }

        return DBHelper.new( name, :log => @log )
      end

      def services_info
        info = []

        @services.values.each do |service|
          info << service[:info]
        end

        info
      end

      def execute_operation( name, operation, *params )
        service = @services[name][:object]

        unless service.respond_to?( operation )
          raise "Operation '#{operation}' is not supported in #{service.class} service"
        end

        if !params.empty? and service.method( operation ).arity != params.size and service.method( operation ).arity >= 0
          raise "Operation '#{operation}' takes #{service.method( operation ).arity } arguments, but provided #{params.size}"
        end

        @log.debug "Executing #{operation} operation for #{service.class}..."

        service.send( operation, *params )
      end

      def service_exists?( name )
        @services.keys.include?(name.to_s)
      end

      def underscore(camel_cased_word)
        camel_cased_word.to_s.gsub(/::/, '/').
                gsub(/([a-z\d])([A-Z])/, '\1_\2').
                tr("-", "_").
                downcase
      end
    end
  end
end
