require 'logger'
require 'ct-agent/helpers/db-helper'
require 'ct-agent/helpers/exec-helper'

class BaseService
  protected

  def prepare( options = {} )
    @log          = options[:log] || Logger.new(STDOUT)
    @exec_helper  = options[:exec_helper] || ExecHelper.new( :log => @log )
    @config       = options[:config] || {}
  end

  def register_service( name, full_name )
    @service  = ServiceManager.register_service( self, name, full_name )
    @db       = DBHelper.new( @service, :log => @log )
  end

  def self.inherited( subclass )
    ServiceManager.register_service_class( subclass )
  end
end