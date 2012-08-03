class FeedItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :activity_type, type: String
  field :activity_attributes, type: Hash

  belongs_to :shop
end
