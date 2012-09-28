class FeedItemSerializer < ActiveModel::Serializer
  attributes :id, :activity_type, :activity_attributes, :created_at
end
