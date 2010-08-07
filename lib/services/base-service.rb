require 'logger'
require 'helpers/db-helper'
require 'helpers/exec-helper'

class BaseService
  protected

  def prepare( options = {} )
    @log          = options[:log] || Logger.new(STDOUT)
    @exec_helper  = options[:exec_helper] || ExecHelper.new( :log => @log )
  end

  def register_service( name, full_name )
    @service  = ServiceManager.instance.register_service( self, name, full_name )
    @db       = DBHelper.new( @service, :log => @log )
  end

  def self.inherited( subclass )
    ServiceManager.instance.register_service_class( subclass )
  end
end