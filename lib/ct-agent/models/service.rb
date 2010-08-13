class Service
  include DataMapper::Resource

  has n, :artifacts
  has n, :events

  property :name, String, :key => true
end