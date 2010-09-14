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
      SteamCannon::LOG.trace "Validating certificate..."

      same = SteamCannon::SSL_DATA[:server_cert].strip == cert.strip

      if same
        SteamCannon::LOG.trace "Provided certificate is valid"
      else
        SteamCannon::LOG.trace "Provided certificate is different!"
      end

      same
    end
  end
end

use Rack::CommonLogger, LogHelper.new( :location => "#{SteamCannon::CONFIG.log_dir}/web.log", :threshold => :trace, :type => :file )

require 'sc-agent/agent'

run SteamCannon::Agent
