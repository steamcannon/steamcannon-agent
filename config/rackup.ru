require 'rack'
require 'sc-agent/agent'

use Rack::CommonLogger

run SteamCannon::Agent
