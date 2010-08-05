require 'singleton'
require 'yaml'

class ConfigHelper
  include Singleton

  def initialize
    @config = YAML.load_file('config/config.yaml')
  end

  attr_reader :config
end