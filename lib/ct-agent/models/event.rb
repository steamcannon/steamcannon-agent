require 'dm-is-tree'

class Event
  include DataMapper::Resource

  belongs_to :service
  is :tree, :order => :id

  property :id, Serial
  property :operation, String
  property :status, String
  property :parent_id, Integer  
  property :msg, String
  property :time, DateTime, :default => Time.now
end