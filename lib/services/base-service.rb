require 'logger'
require 'helpers/db-helper'

class BaseService
  protected

  def prepare( options = {} )
    @log  = options[:log] || Logger.new(STDOUT)
    @db   = DBHelper.new( self.class, :log => @log )
  end

  def register_service( name, full_name )
    ServiceManager.instance.register_service( self, name, full_name )
  end

  def self.inherited( subclass )
    ServiceManager.instance.register_service_class( subclass )
  end
end