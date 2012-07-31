class Shop
  include Mongoid::Document

  field :shopify_id, type: Integer
  field :shopify_token, type: String
  field :domain, type: String
  field :shopify_attributes, type: Hash, default: {}
  field :token, type: String

  belongs_to :user

  validates :shopify_id, presence: true
  validates :shopify_token, presence: true
  validates :token, uniqueness: true

  before_create :generate_token
  after_create :reset_redis_keys

  # Public: Setup Shopify shop - webhooks & script tag.
  def setup_shopify_shop
    with_shopify_session do |session|
      setup_shopify_script_tag
      setup_shopify_webhooks
    end
  end

  # Internal: Setup Shopify script tag.
  def setup_shopify_script_tag
    ShopifyAPI::ScriptTag.create src: tracker_script_url, event: 'onload'
  end

  # Internal: Setup Shopify webhooks.
  def setup_shopify_webhooks
    ShopifyAPI::Webhook.create topic: 'orders/create', address: new_order_webhook_url, format: 'json'
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

  # Internal: Redis conversion rate key.
  def conversion_rate_key
    redis_prefixed 'conversion_rate'
  end

  # Internal: Redis total sales today key.
  def total_sales_today_key
    redis_prefixed 'total_sales_today'
  end

  # Internal: Redis checkout distribution key.
  def checkout_distribution_key
    redis_prefixed 'co_distribution'
  end

  # Public: Get avg purchase.
  def avg_purchase
    $redis.get avg_purchase_key
  end

  # Public: Get conversion rate.
  def conversion_rate
    $redis.get conversion_rate_key
  end

  # Public: Get total sales today.
  def total_sales_today
    $redis.get total_sales_today_key
  end

  # Public: Get checkout distribution.
  def checkout_distribution
    $redis.get(checkout_distribution_key).try(:split, ',').try(:map, &:to_i)
  end

  # Internal: Get URL of new order webhook for current shop.
  def new_order_webhook_url
    "http://#{ENV['COLLECTOR_HOST']}/webhooks/shopify/#{token}/new_order"
  end

  def self.find_or_create_with_omniauth(shop_host, token)
    shopify = shopify_shop(shop_host, token)

    return nil unless shopify

    shop = Shop.find_or_initialize_by(shopify_id: shopify.id, shopify_token: token)
    new_shop = shop.new_record?
    shop.shopify_attributes = shopify.attributes
    shop.domain = shop.shopify_attributes.fetch('domain', nil) || shop_host
    shop.save
    shop.setup_shopify_shop if new_shop
    shop
  end

  # Public: Get ShopifyAPI::Shop.
  #
  # shop  - The String shop domain.
  # token - The String OAuth 2 token.
  def self.shopify_shop(shop, token)
    with_shopify_session(shop, token) do |session|
      session.shop
    end
  end

  # Public: Get ShopifyAPI::Shop for current shop.
  def shopify_shop
    Shop.shopify_shop domain, shopify_token
  end

  def self.with_shopify_session(shop, token, &block)
    begin
      logger.debug "Creating new session #{shop} - #{token}"
      session = ShopifyAPI::Session.new shop, token
      ShopifyAPI::Base.activate_session session

      block.call session if session.valid?
    ensure
      ShopifyAPI::Base.clear_session
    end
  end

  def with_shopify_session(&block)
    Shop.with_shopify_session domain, shopify_token do |session|
      block.call session
    end
  end

  def generate_token
    self.token = Devise.friendly_token
  end

  def reset_redis_keys
    $redis.set avg_purchase_key, 0.0 unless avg_purchase
    $redis.set conversion_rate_key, 0.0 unless conversion_rate
    $redis.set total_sales_today_key, 0.0 unless total_sales_today
    $redis.set checkout_distribution_key, '' unless checkout_distribution
  end
end
