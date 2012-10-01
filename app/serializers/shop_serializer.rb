class ShopSerializer < ActiveModel::Serializer
  attributes :id, :shopify_id, :domain, :token, :avg_purchase,
    :max_avg_purchase, :conversion_rate, :max_conversion_rate,
    :total_sales_today, :checkout_distribution, :top_links, :top_searches,
    :top_products, :shopify_attributes, :send_daily_notifications

  has_one :user, embed: :ids
  has_many :feed_items

  def feed_items
    shop.feed
  end
end
