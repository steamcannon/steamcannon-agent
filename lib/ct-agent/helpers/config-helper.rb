require 'openhash/openhash'
require 'ct-agent/helpers/client-helper'
require 'logger'
require 'yaml'

module CoolingTower
  class ConfigHelper
    def initialize( options = {} )
      @log            = options[:log]           || Logger.new(STDOUT)

      defaults = {
              'log_level' => :info
      }

      @config_location = 'config/agent.yaml'

      # TODO this should be probably removed and a config file used provided by CT with location stored in UserData

      begin
        @config = OpenHash.new(defaults.merge(YAML.load_file( @config_location )))
      rescue
        puts "Could not read config file: '#{@config_location}'."
        exit 1
      end

      # TODO here we need also grab certificates and config location from platform dependent

      detect_platform
    end

    def detect_platform
      @log.info "Discovering platform..."

      platform = nil

      # File.read( "/etc/sysconfig/ct" )


      # TODO remove this!!!
      platform = :ec2

      raise "Unsupported platform!" if platform.nil?

      @log.info "We're on '#{platform}' platform"

      @config.platform = platform
    end

    attr_reader :config
  end
end
