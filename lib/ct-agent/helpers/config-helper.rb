require 'openhash/openhash'
require 'logger'
require 'yaml'

module CoolingTower
  class ConfigHelper
    def initialize

      defaults = {
              'log_level' => :info
      }

      @config_location = 'config/agent.yaml'

      begin
        @config = OpenHash.new(defaults.merge(YAML.load_file( @config_location )))
      rescue
        puts "Could not read config file: '#{@config_location}'."
        exit 1
      end
    end

    attr_reader :config
  end
end
