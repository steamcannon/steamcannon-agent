require 'logger'
require 'models/artifact'

class DBHelper
  def initialize( clazz, options = {} )
    @clazz  = clazz
    @log    = options[:log] || Logger.new(STDOUT)
  end

  def save_artifact( name, location )
    Artifact.create( :name => name, :location => location )
  end

  def get_artifact( id )
    Artifact.get( id )
  end
end