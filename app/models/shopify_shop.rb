class ShopifyShop < Shop
  field :shopify_id, type: Integer
  field :shopify_token, type: String
  field :shopify_attributes, type: Hash, default: {}

  validates :shopify_id, presence: true
  validates :shopify_token, presence: true

  attr_accessible :shopify_id, :shopify_token, :shopify_attributes, as: :admin

  before_create :extract_shopify_attributes

  # Internal: Extract required shop attributes from shopify payload.
  def extract_shopify_attributes
    self.domain = shopify_attributes['domain']
    self.name = shopify_attributes['name']
    self.timezone = shopify_attributes['timezone'].sub /\([^)]*\) /, ''
  end 

  # Public: Get ShopifyAPI::Shop for current shop.
  def shopify_shop
    ShopifyShop.shopify_shop domain, shopify_token
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

  def with_shopify_session(&block)
    ShopifyShop.with_shopify_session domain, shopify_token, &block
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

  # Public: Create shopify session and execute some code within it.
  #
  # shop  - The String shop domain name.
  # token - The String shopify shop token.
  # block - A block of code to be executed within the session.
  def self.with_shopify_session(shop, token, &block)
    logger.debug "Creating new session #{shop} - #{token}"

    ShopifyAPI::Session.temp shop, token do
      yield
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

  def self.create_with_omniauth_and_user(shop_host, token, user)
    shopify = shopify_shop(shop_host, token)

    return nil unless shopify

    shop = ShopifyShop.new({shopify_id: shopify.id, shopify_token: token,
      shopify_attributes: shopify.attributes}, as: :admin)
    shop.user = user
    shop.extract_shopify_attributes

    if shop.save
      shop.setup_shopify_shop

      shop
    else
      nil
    end
  end
end
