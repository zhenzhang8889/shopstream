class Shop
  include Mongoid::Document

  field :shopify_id, type: Integer
  field :shopify_token, type: String
  field :name, type: String
  field :domain, type: String
  field :timezone, type: String
  field :shopify_attributes, type: Hash, default: {}
  field :token, type: String
  field :send_daily_notifications, type: Boolean, default: true

  belongs_to :user
  has_many :feed_items

  validates :shopify_id, presence: true
  validates :shopify_token, presence: true
  validates :token, uniqueness: true
  validates :name, presence: true
  validates :doman, presence: true
  validates :timezone, presence: true

  before_create :generate_token
  before_create :extract_shopify_attributes
  after_create :reset_redis_keys

  def feed
    feed_items.desc(:created_at).limit(10).to_a
  end
  
  # Public: Setup Shopify shop - webhooks & script tag.
  def setup_shopify_shop
    with_shopify_session do
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
    setup_shopify_webhook 'orders/create', :new_order
    setup_shopify_webhook 'carts/create', :new_cart
    setup_shopify_webhook 'carts/update', :updated_cart
    setup_shopify_webhook 'app/uninstalled', :app_uninstalled
  end

  # Internal: Setup Shopify webhook.
  #
  # topic - The String webhook topic.
  # url   - The Symbol webhook url.
  def setup_shopify_webhook(topic, meth)
    unless ShopifyAPI::Webhook.count(topic: topic) > 0
      address = send :webhook_url, meth
      ShopifyAPI::Webhook.create topic: topic, address: address, format: 'json'
    end
  end

  # Internal: Setup Shopify billing.
  def setup_shopify_billing(return_url)
    with_shopify_session do
      unless ShopifyAPI::RecurringApplicationCharge.current
        charge = ShopifyAPI::RecurringApplicationCharge.create name: 'Basic plan',
          price: 9.99,
          trial: 30,
          test: ENV['SHOPIFY_TEST'] == 'YES',
          return_url: return_url

        charge.confirmation_url
      end
    end
  end

  # Intrnal: Activate recurring charge.
  def activate_shopify_recurring_charge(charge_id)
    shopify_shop

    with_shopify_session do
      ShopifyAPI::RecurringApplicationCharge.find(charge_id).activate
    end
  end

  def self.activate_shopify_recurring_charge(domain, charge_id)
    find_by(domain: domain).activate_shopify_recurring_charge charge_id
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

  def self.create_with_omniauth_and_user(shop_host, token, user)
    shopify = shopify_shop(shop_host, token)

    return nil unless shopify

    shop = Shop.create shopify_id: shopify.id, shopify_token: token,
      shopify_attributes: shopify.attributes, user: user
    shop.setup_shopify_shop
    shop
  end

  # Public: Get ShopifyAPI::Shop.
  #
  # shop  - The String shop domain.
  # token - The String OAuth 2 token.
  def self.shopify_shop(shop, token)
    with_shopify_session(shop, token) do
      ShopifyAPI::Shop.current
    end
  end

  # Public: Get ShopifyAPI::Shop for current shop.
  def shopify_shop
    Shop.shopify_shop domain, shopify_token
  end

  def self.with_shopify_session(shop, token, &block)
    logger.debug "Creating new session #{shop} - #{token}"

    ShopifyAPI::Session.temp shop, token do
      yield
    end
  end

  def with_shopify_session(&block)
    Shop.with_shopify_session domain, shopify_token, &block
  end

  def generate_token
    self.token = Devise.friendly_token
  end

  def extract_shopify_attributes
    self.domain = shopify_attributes['domain']
    self.name = shopify_attributes['name']
    self.timezone = shopify_attributes['timezone'].sub /\([^)]*\) /, ''
  end

  def reset_redis_keys
    $redis.set avg_purchase_key, 0.0 unless avg_purchase
    $redis.set max_avg_purchase_key, 0.0 unless max_avg_purchase
    $redis.set conversion_rate_key, 0.0 unless conversion_rate
    $redis.set max_conversion_rate_key, 0.0 unless max_conversion_rate
    $redis.set total_sales_today_key, 0.0 unless total_sales_today
    $redis.set checkout_distribution_key, '[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]' unless checkout_distribution
  end
end
