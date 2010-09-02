require 'rack'
require 'sc-agent/helpers/log-helper'
require 'sc-agent/agent'

use Rack::CommonLogger, LogHelper.new( :location => 'log/web.log', :threshold => :trace, :type => :file )

run SteamCannon::Agent
