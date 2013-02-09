class Shop
  include Mongoid::Document
  include Mongoid::Timestamps
  include Analyzing::Eventful
  include Analyzing::Gaugeable

  has_events :requests, :orders

  has_metrics visitors: { period: -> { 5.minutes.ago..Time.now } },
    sales: { period: ->{ today }, max: 30, change: 1 },
    orders: { period: ->{ today } },
    average_purchase: { period: ->{ today }, max: 30 },
    revenue_per_visitor: { period: ->{ today }, max: 30 },
    conversion_rate: { period: ->{ today }, max: 30 }

  has_top products: { period: ->{ today } },
    links: { period: ->{ today } },
    searches: { period: ->{ today } }

  field :token, type: String
  field :name, type: String
  field :domain, type: String
  field :timezone, type: String
  field :timezone_name, type: String
  field :timezone_abbr, type: String
  field :send_daily_notifications, type: Boolean, default: true
  field :sound_on_sales, type: Boolean, default: true

  belongs_to :user
  has_many :feed_items

  validates :token, uniqueness: true
  validates :name, presence: true
  validates :domain, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone::MAPPING.to_a.flatten }

  attr_accessible :name, :domain, :timezone, :send_daily_notifications,
    :sound_on_sales
  attr_accessible :name, :domain, :timezone, :token, :send_daily_notifications,
    :sound_on_sales, as: :admin

  before_create :generate_token
  after_create :reset_redis_keys
  before_save :set_timezone_name

  after_refresh_gauges :push_gauges

  def push_gauges
  end

  def today
    26.days.ago.beginning_of_day..26.days.ago.end_of_day.ceil
  end

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
    Shop.all.to_a.select(&:interested_in_tracked_nothing_notification?)
  end

  def self.active
    all.select(&:tracked_recently?)
  end

  def self.inactive
    all.select(&:ever_tracked?).reject(&:tracked_recently?)
  end

  def self.never_tracked
    all.reject(&:ever_tracked?)
  end

  def set_timezone_name
    self.timezone_name = tz.to_s
    self.timezone_abbr = tz.tzinfo.name
  end

  def active_model_serializer
    ShopSerializer
  end
end
