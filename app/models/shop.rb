class Shop
  include Mongoid::Document
  include Mongoid::Timestamps

  field :token, type: String
  field :name, type: String
  field :domain, type: String
  field :timezone, type: String
  field :timezone_name, type: String
  field :send_daily_notifications, type: Boolean, default: true
  field :sound_on_sales, type: Boolean, default: true

  belongs_to :user
  has_many :feed_items

  validates :token, uniqueness: true
  validates :name, presence: true
  validates :domain, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone.zones_map.keys }

  attr_accessible :name, :domain, :timezone, :send_daily_notifications,
    :sound_on_sales
  attr_accessible :name, :domain, :timezone, :token, :send_daily_notifications,
    :sound_on_sales, as: :admin

  before_create :generate_token
  after_create :set_timezone_name
  after_create :reset_redis_keys

  # Public: Get 10 most recent feed items.
  def feed
    feed_items.desc(:created_at).limit(10).to_a
  end

  # Public: Get TimeZone object for shop's time zone.
  def tz
    ActiveSupport::TimeZone.new timezone
  end

  # Internal: Get URL of tracker script for current shop.
  def tracker_script_url
    "https://#{ENV['COLLECTOR_HOST']}/track-#{token}.js"
  end

  # Internal: Redis prefix.
  def redis_prefix
    "shop_#{token}"
  end

  # Internal: Prefix a string with redis prefix for current shop.
  def redis_prefixed(key)
    "#{redis_prefix}_#{key}"
  end

  # Internal: Redis live visitors key.

  def live_visitors_key
    redis_prefixed 'live_visitors'
  end

  # Internal: Redis average purchase key.
  def avg_purchase_key
    redis_prefixed 'avg_purchase'
  end

  # Internal: Redis max average purchase key.
  def max_avg_purchase_key
    redis_prefixed 'max_avg_purchase'
  end

  # Internal: Redis RVP key.
  def revenue_per_visit_key
    redis_prefixed 'revenue_per_visit'
  end

  # Internal: Redis max RVP key.
  def max_revenue_per_visit_key
    redis_prefixed 'max_revenue_per_visit'
  end

  # Internal: Redis conversion rate key.
  def conversion_rate_key
    redis_prefixed 'conversion_rate'
  end

  # Internal: Redis max conversion rate key.
  def max_conversion_rate_key
    redis_prefixed 'max_conversion_rate'
  end

  # Internal: Redis total orders today key.
  def total_orders_today_key
    redis_prefixed 'total_orders_today'
  end

  # Internal: Redis total sales today key.
  def total_sales_today_key
    redis_prefixed 'total_sales_today'
  end

  # Internal: Redis max total sales key.
  def max_total_sales_today_key
    redis_prefixed 'max_total_sales_today'
  end

  # Internal: Redis checkout distribution key.
  def checkout_distribution_key
    redis_prefixed 'co_distribution'
  end

  # Internal: Redis top links key.
  def top_links_key
    redis_prefixed 'top_links'
  end

  # Internal: Redis top searched key.
  def top_searches_key
    redis_prefixed 'top_searches'
  end

  # Internal: Redis top products key.
  def top_products_key
    redis_prefixed 'top_products'
  end

  # Internal: Redis last tracked at key.
  def last_tracked_at_key
    redis_prefixed 'last_tracked_at'
  end

  # Public: Get live visitors.
  def live_visitors
    $redis.get(live_visitors_key).to_i
  end

  # Public: Get avg purchase.
  def avg_purchase
    $redis.get(avg_purchase_key).to_f
  end

  # Public: Get max average purchase.
  def max_avg_purchase
    $redis.get(max_avg_purchase_key).to_f
  end

  # Public: Get RVP.
  def revenue_per_visit
    $redis.get(revenue_per_visit_key).to_f
  end

  # Public: Get max RVP.
  def max_revenue_per_visit
    $redis.get(max_revenue_per_visit_key).to_f
  end

  # Public: Get conversion rate.
  def conversion_rate
    $redis.get(conversion_rate_key).to_f
  end

  # Public: Get max conversion rate.
  def max_conversion_rate
    $redis.get(max_conversion_rate_key).to_f
  end

  # Public: Get total orders today.
  def total_orders_today
    $redis.get(total_orders_today_key).to_f
  end

  # Public: Get total sales today.
  def total_sales_today
    $redis.get(total_sales_today_key).to_f
  end

  # Public: Get max total sales.
  def max_total_sales_today
    $redis.get(max_total_sales_today_key).to_f
  end

  # Public: Get checkout distribution.
  def checkout_distribution
    $redis.get(checkout_distribution_key).try(:split, ',').try(:map, &:to_i)
  end

  # Public: Get top links.
  def top_links
    $redis.zrange top_links_key, 0, 9
  end

  # Public: Get top searches.
  def top_searches
    $redis.zrange top_searches_key, 0, 9
  end

  # Public: Get top products.
  def top_products
    $redis.zrange top_products_key, 0, 9
  end

  # Public: Query when the store has tracked anything.
  def last_tracked_at
    $redis.get(last_tracked_at_key).try(:to_time)
  end

  # Public: Check if store was ever tracked.
  def ever_tracked?
    !!last_tracked_at
  end

  # Public: Check if store was tracked in past 24 hours.
  def tracked_recently?
    if ever_tracked?
      last_tracked_at > 24.hours.ago
    else
      false
    end
  end

  # Internal: Generate webhook url for specified action.
  def webhook_url(action)
    "http://#{ENV['COLLECTOR_HOST']}/webhooks/shopify/#{token}/#{action}"
  end

  # Internal: Generate shop token.
  def generate_token
    self.token = Devise.friendly_token
  end

  def shopify?
    _type == "ShopifyShop"
  end

  def custom?
    _type == "CustomShop"
  end

  # Internal: Reset all redis keys to default values in case those values are
  # blank currently.
  def reset_redis_keys
    $redis.set avg_purchase_key, 0.0 unless avg_purchase
    $redis.set max_avg_purchase_key, 0.0 unless max_avg_purchase
    $redis.set revenue_per_visit_key, 0.0 unless revenue_per_visit
    $redis.set max_revenue_per_visit_key, 0.0 unless max_revenue_per_visit
    $redis.set conversion_rate_key, 0.0 unless conversion_rate
    $redis.set max_conversion_rate_key, 0.0 unless max_conversion_rate
    $redis.set total_orders_today_key, 0.0 unless total_orders_today
    $redis.set total_sales_today_key, 0.0 unless total_sales_today
    $redis.set max_total_sales_today_key, 0.0 unless max_total_sales_today
    $redis.set checkout_distribution_key, '[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]' unless checkout_distribution
    $redis.set last_tracked_at_key, '' unless last_tracked_at
  end

  # Internal: Find shops interested in daily reports, for specified `time`.
  #
  # time   - The Time object.
  # offset - The Integer offset.
  def self.interested_in_reports(time, offset = -1)
    # Only those in which time zone it's midnight now
    hour_offset = time.utc.hour - offset

    shops = where(send_daily_notifications: true).to_a

    shops.select! do |shop|
      shop.tz.utc_offset / 3600 == -hour_offset
    end

    shops
  end

  def hours_not_tracked
    seconds = Time.now - (last_tracked_at || created_at)
    (seconds / 60 / 60).to_i
  end

  def days_not_tracked
    (hours_not_tracked / 24).to_i
  end

  def interested_in_tracked_nothing_notification?
    if !tracked_recently? || !ever_tracked?
      if ever_tracked?
        hours_not_tracked % 24 == 0
      else
        [3 * 24, 6 * 24, 9 * 24].include? hours_not_tracked
      end
    end
  end

  def self.interested_in_tracked_nothing_notification
    Shop.all.to_a.select &:interested_in_tracked_nothing_notification?
  end

  def set_timezone_name
    self.update_attribute :timezone_name, tz.to_s
  end

  def active_model_serializer
    ShopSerializer
  end
end
