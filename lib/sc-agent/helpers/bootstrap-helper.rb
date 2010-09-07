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

require 'sc-agent/helpers/log-helper'
require 'sc-agent/managers/db-manager'
require 'sc-agent/managers/service-manager'
require 'sc-agent/helpers/config-helper'
require 'sc-agent/helpers/ssl-helper'
require 'fileutils'
require 'rack'

module SteamCannon
  class BootstrapHelper
    attr_reader :config

    def initialize
      @log = LogHelper.new( :location => 'log/agent.log', :threshold => :debug )
    end

    def prepare
      @log.info "Initializing Agent..."

      read_config
      prepare_certificate

      DBManager.new( :log => @log ).prepare_db
      ServiceManager.prepare( @config, @log ).load_services
    end

    def read_config
      @config = ConfigHelper.new( :log => @log ).config
      @log.change_threshold( @config.log_level.to_sym )

      @log.trace @config.to_yaml
    end

    def prepare_certificate
      @log.debug "Initializing certificate..."

      key_file    = "#{@config['ssl_dir']}/#{@config['ssl_key_file_name']}"
      cert_file   = "#{@config['ssl_dir']}/#{@config['ssl_cert_file_name']}"

      unless File.directory?( @config['ssl_dir'] ) and File.exists?( key_file ) and File.exists?( cert_file )

        begin
          FileUtils.mkdir_p( @config['ssl_dir'] )
        rescue => e
          @log.error e
          @log.error "Couldn't create directory '#{@config['ssl_dir']}' do you have sufficient rights?"
          abort
        end

        @log.info "Generating new self-signed certificate..."

        cert, key = SSLHelper.new.create_self_signed_cert( 1024, [["C", "US"],["ST", "NC"], ["O", "Red Hat"], ["CN", "localhost"]] )

        File.open( key_file, 'w') { |f| f.write( key.to_pem ) }

        File.open( cert_file, 'w') do |f|
          f.write( cert.to_text )
          f.write( cert.to_pem )
        end

        @log.debug "Self-signed certificate successfully generated."
      else
        @log.debug "Certificate already exists."
      end

      @log.debug "Certificate initialization done."
    end
  end
end
