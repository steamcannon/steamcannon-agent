require 'logger'
require 'helpers/db-helper'

class BaseService
  def initialize( options = {} )
    @log = options[:log] || Logger.new(STDOUT)

    @db   = DBHelper.new( self.class, :log => @log )
  end

  protected

  def after_init
    
  end

  def register( name, full_name )
    ServiceManager.instance.register_service( self, name, full_name )
  end

  def self.inherited( subclass )
    ServiceManager.instance.register_service_class( subclass )
  end
end