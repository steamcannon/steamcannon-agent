class Service
  include DataMapper::Resource

  has n, :artifacts

  property :name, String, :key => true
end