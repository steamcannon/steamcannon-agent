require 'logger'
require 'models/event'

class DBManager
  def initialize( options = {} )
    DataMapper::Logger.new( STDOUT, :debug )
  end

  def prepare_db
    DataMapper.setup(:default, 'sqlite::memory:')
    DataMapper.finalize
    DataMapper.auto_migrate!
  end
end