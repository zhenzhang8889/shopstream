class ShopSerializer < ActiveModel::Serializer
  attributes :id, :type, :domain, :token, :name, :timezone, :live_visitors,
    :avg_purchase, :max_avg_purchase, :revenue_per_visit,
    :max_revenue_per_visit, :conversion_rate, :max_conversion_rate,
    :total_orders_today, :total_sales_today, :max_total_sales_today,
    :checkout_distribution, :top_links, :top_searches, :top_products,
    :tracker_script_url, :send_daily_notifications, :sound_on_sales,
    :ever_tracked?, :tracked_recently?

  has_one :user, embed: :ids, key: :user_id
  has_many :feed_items

  def feed_items
    shop.feed
  end

  def type
    case shop._type
    when "ShopifyShop"
      "shopify"
    when "CustomShop"
      "custom"
    end
  end
end
