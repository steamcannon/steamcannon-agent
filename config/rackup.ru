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
end

module Thin
  class Connection
    def ssl_verify_peer( cert )
      SteamCannon::SSL_DATA[:server_cert].strip == cert.strip
    end
  end
end

use Rack::CommonLogger, LogHelper.new( :location => "#{SteamCannon::CONFIG.log_dir}/web.log", :threshold => :trace, :type => :file )

require 'sc-agent/agent'

run SteamCannon::Agent
