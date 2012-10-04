class Shop
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :domain, type: String
  field :timezone, type: String
  field :token, type: String
  field :send_daily_notifications, type: Boolean, default: true

  belongs_to :user
  has_many :feed_items

  validates :token, uniqueness: true
  validates :name, presence: true
  validates :domain, presence: true
  validates :timezone, presence: true

  attr_accessible :name, :send_daily_notifications
  attr_accessible :name, :domain, :timezone, :token, :send_daily_notifications,
    as: :admin

  before_create :generate_token
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
    "http://#{ENV['COLLECTOR_HOST']}/track-#{token}.js"
  end

  # Internal: Redis prefix.
  def redis_prefix
    "shop_#{token}"
  end

  # Internal: Prefix a string with redis prefix for current shop.
  def redis_prefixed(key)
    "#{redis_prefix}_#{key}"
  end

  # Internal: Redis average purchase key.
  def avg_purchase_key
    redis_prefixed 'avg_purchase'
  end

  # Internal: Redis max average purchase key.
  def max_avg_purchase_key
    redis_prefixed 'max_avg_purchase'
  end

  # Internal: Redis conversion rate key.
  def conversion_rate_key
    redis_prefixed 'conversion_rate'
  end

  # Internal: Redis max conversion rate key.
  def max_conversion_rate_key
    redis_prefixed 'max_conversion_rate'
  end

  # Internal: Redis total sales today key.
  def total_sales_today_key
    redis_prefixed 'total_sales_today'
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

  # Public: Get avg purchase.
  def avg_purchase
    $redis.get(avg_purchase_key).to_f
  end

  # Public: Get max average purchase.
  def max_avg_purchase
    $redis.get(max_avg_purchase_key).to_f
  end

  # Public: Get conversion rate.
  def conversion_rate
    $redis.get(conversion_rate_key).to_f
  end

  # Public: Get max conversion rate.
  def max_conversion_rate
    $redis.get(max_conversion_rate_key).to_f
  end

  # Public: Get total sales today.
  def total_sales_today
    $redis.get(total_sales_today_key).to_f
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

  # Internal: Generate webhook url for specified action.
  def webhook_url(action)
    "http://#{ENV['COLLECTOR_HOST']}/webhooks/shopify/#{token}/#{action}"
  end

  # Internal: Generate shop token.
  def generate_token
    self.token = Devise.friendly_token
  end

  # Internal: Reset all redis keys to default values in case those values are
  # blank currently.
  def reset_redis_keys
    $redis.set avg_purchase_key, 0.0 unless avg_purchase
    $redis.set max_avg_purchase_key, 0.0 unless max_avg_purchase
    $redis.set conversion_rate_key, 0.0 unless conversion_rate
    $redis.set max_conversion_rate_key, 0.0 unless max_conversion_rate
    $redis.set total_sales_today_key, 0.0 unless total_sales_today
    $redis.set checkout_distribution_key, '[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]' unless checkout_distribution
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

  def active_model_serializer
    ShopSerializer
  end
end
