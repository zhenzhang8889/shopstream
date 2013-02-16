class ShopSerializer < ActiveModel::Serializer
  attributes :id, :type, :domain, :token, :name, :timezone,
    :tracker_script_url, :send_daily_notifications, :sound_on_sales,
    :ever_tracked?, :tracked_recently?

  has_one :user, embed: :ids, key: :user_id
  has_many :feed_items

  def attributes
    hash = super

    hash.merge(object.gauge_values)
  end

  def feed_items
    object.feed
  end

  def type
    case object._type
    when "ShopifyShop"
      "shopify"
    when "CustomShop"
      "custom"
    end
  end
end
