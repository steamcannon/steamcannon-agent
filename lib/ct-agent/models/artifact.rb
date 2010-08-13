class Artifact
  include DataMapper::Resource

  belongs_to :service

  property :id, Serial
  property :location, String
  property :name, String
end