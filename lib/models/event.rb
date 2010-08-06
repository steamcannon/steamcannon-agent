class Event
  include DataMapper::Resource

  property :id, Serial
  property :service, String
  property :operation, String
  property :time, DateTime
end