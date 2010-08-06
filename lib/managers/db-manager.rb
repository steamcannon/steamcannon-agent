require 'logger'
require 'models/service'
require 'models/event'
require 'models/artifact'

class DBManager
  def initialize( options = {} )
    DataMapper::Logger.new( STDOUT, :debug )
  end

  def prepare_db
    DataMapper::Model.raise_on_save_failure = true
    DataMapper.setup(:default, 'sqlite::memory:')
    DataMapper.finalize
    DataMapper.auto_migrate!
  end
end