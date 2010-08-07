class Event
  include DataMapper::Resource

  belongs_to :service

  property :id, Serial
  property :operation, String
  property :status, String
  property :time, DateTime, :default => Time.now
end