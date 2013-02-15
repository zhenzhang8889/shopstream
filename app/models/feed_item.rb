class FeedItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :activity_type, type: String
  field :activity_attributes, type: Hash

  belongs_to :shop, validate: true

  after_create :push_item

  def push_item
    shop.pusher.trigger('feed-item-created', to_json)
  end
end
