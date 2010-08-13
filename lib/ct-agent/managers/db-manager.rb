require 'logger'
require 'ct-agent/models/service'
require 'ct-agent/models/event'
require 'ct-agent/models/artifact'

class DBManager
  def initialize( options = {} )
    @log  = options[:log] || Logger.new(STDOUT)

    DataMapper::Logger.new( @log, :debug )
  end

  def prepare_db
    DataMapper::Model.raise_on_save_failure = true
    DataMapper.setup(:default, 'sqlite::memory:')
    DataMapper.finalize
    DataMapper.auto_migrate!
  end
end