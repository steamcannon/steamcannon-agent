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

require 'openssl'
require 'logger'

module SteamCannon
  class SSLHelper
    def initialize( config, options = {} )
      @config         = config
      @log            = options[:log] || Logger.new(STDOUT)
      @cloud_helper   = options[:cloud_helper] || CloudHelper.new( :log => @log )

      @key_file          = "#{@config['ssl_dir']}/#{@config['ssl_key_file_name']}"
      @cert_file         = "#{@config['ssl_dir']}/#{@config['ssl_cert_file_name']}"
      @server_cert_file  = "#{@config['ssl_dir']}/server_cert.pem"
    end

    def ssl_data
      @log.debug "Initializing certificate..."

      unless File.directory?( @config['ssl_dir'] )
        begin
          FileUtils.mkdir_p( @config['ssl_dir'] )
        rescue => e
          @log.error e
          @log.error "Couldn't create directory '#{@config['ssl_dir']}' do you have sufficient rights?"
          abort
        end
      end

      @log.info "Reading server certificate..."

      server_cert = @cloud_helper.read_certificate( @config.platform )

      raise "Couldn't load public server certificate" if server_cert.nil?

      @log.debug "Server certificate read."

      unless File.exists?( @key_file ) and File.exists?( @cert_file )
        @log.info "Generating new self-signed certificate..."

        generate_self_signed_cert

        @log.debug "Self-signed certificate generated."
      else
        @log.info "Using already existing certificate."
      end

      { :cert => File.read( @cert_file ), :key => File.read( @key_file ), :server_cert => File.read( @server_cert_file ) }
    end

    def generate_self_signed_cert
      cert, key = create_self_signed_cert( 1024, [["C", "US"], ["ST", "NC"], ["O", "Red Hat"], ["CN", "localhost"]] )

      File.open( @key_file, 'w') { |f| f.write( key.to_pem ) }

      File.open( @cert_file, 'w') do |f|
        f.write( cert.to_text )
        f.write( cert.to_pem )
      end
    end

    def create_self_signed_cert( length, cn )
      rsa = OpenSSL::PKey::RSA.new( length )
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 0
      name = OpenSSL::X509::Name.new(cn)
      cert.subject = name
      cert.issuer = name
      cert.not_before = Time.now
      cert.not_after = Time.now + (1*24*60*60)
      cert.public_key = rsa.public_key

      ef = OpenSSL::X509::ExtensionFactory.new(nil, cert)
      ef.issuer_certificate = cert
      cert.extensions = [
              ef.create_extension("basicConstraints", "CA:FALSE"),
              ef.create_extension("keyUsage", "keyEncipherment"),
              ef.create_extension("subjectKeyIdentifier", "hash"),
              ef.create_extension("extendedKeyUsage", "serverAuth")
      ]
      aki = ef.create_extension("authorityKeyIdentifier",
                                "keyid:always,issuer:always")
      cert.add_extension(aki)
      cert.sign(rsa, OpenSSL::Digest::SHA1.new)

      return [ cert, rsa ]
    end
  end
end
