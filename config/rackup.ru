require 'rack'
require 'ct-agent/agent'

use Rack::CommonLogger

run CoolingTower::Agent
