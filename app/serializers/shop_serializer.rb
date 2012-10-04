class ShopSerializer < ActiveModel::Serializer
  attributes :id, :type, :domain, :token, :name, :timezone, :avg_purchase,
    :max_avg_purchase, :conversion_rate, :max_conversion_rate,
    :total_sales_today, :checkout_distribution, :top_links, :top_searches,
    :top_products, :tracker_script_url, :send_daily_notifications

  has_one :user, embed: :ids, key: :user_id
  has_many :feed_items

  def feed_items
    shop.feed
  end

  def type
    case shop._type
    when "ShopifyShop"
      "shopify"
    when "CutomShop"
      "custom"
    end
  end
end
