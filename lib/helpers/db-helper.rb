require 'logger'

class DBHelper
  def initialize( clazz, options = {} )
    @clazz  = clazz
    @log    = options[:log] || Logger.new(STDOUT)
  end

  def store_event

  end


end