require 'rubygems'
require 'rack'

$:<<'lib'

require 'sc-agent/helpers/log-helper'
require 'sc-agent/helpers/config-helper'
require 'sc-agent/helpers/bootstrap-helper'

module SteamCannon
  CONFIG  = ConfigHelper.new.config

  bootstrap_helper = BootstrapHelper.new( CONFIG )
  bootstrap_helper.prepare

  SSL_DATA  = bootstrap_helper.ssl_data
  LOG       = bootstrap_helper.log
end


module Thin
  class Connection
    def ssl_verify_peer( cert )
      
      SteamCannon::LOG.trace "Validating peer certificate..."

      if SteamCannon::SSL_DATA[:client_ca_cert].nil? or SteamCannon::SSL_DATA[:client_ca_cert].length == 0
        SteamCannon::LOG.warn "No CA certificate to validate peer"
        return false
      end

      ca_x509 = OpenSSL::X509::Certificate.new(SteamCannon::SSL_DATA[:client_ca_cert])

      begin
        cert_x509 = OpenSSL::X509::Certificate.new(cert)
      rescue => e
        SteamCannon::LOG.trace e.message
        SteamCannon::LOG.trace "Provided certificate is invalid"
        return false
      end

      valid = (SteamCannon::SSL_DATA[:client_ca_cert].strip == cert.strip) || cert_x509.verify(ca_x509.public_key)

      if valid
        SteamCannon::LOG.trace "Provided certificate is valid"
      else
        SteamCannon::LOG.trace "Provided certificate is neither the client CA nor a cert signed by the client CA"

        SteamCannon::LOG.trace "Client CA certificate we have:\n#{SteamCannon::SSL_DATA[:client_ca_cert].strip}"
        SteamCannon::LOG.trace "Subject: #{ca_x509.subject}"
        
        SteamCannon::LOG.trace "Certificate received:\n#{cert.strip}"
        SteamCannon::LOG.trace "Issuer: #{cert_x509.issuer}"
      end

      valid
    end
  end
end

use Rack::CommonLogger, LogHelper.new( :location => "#{SteamCannon::CONFIG.log_dir}/web.log", :threshold => :trace, :type => :file )

require 'sc-agent/agent'

run SteamCannon::Agent
