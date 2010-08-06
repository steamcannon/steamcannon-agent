class Event
  include DataMapper::Resource

  property :id, Serial
  property :service, String
end