class Shop
  include Mongoid::Document

  field :shopify_id, type: Integer
  field :shopify_token, type: String
  field :shopify_attributes, type: Hash
  field :token, type: String

  belongs_to :user

  validates :shopify_id, presence: true
  validates :shopify_token, presence: true
  validates :token, uniqueness: true

  before_create :generate_token

  def self.find_or_create_with_omniauth(shop_host, token)
    shopify = shopify_shop(shop_host, token)

    return nil unless shopify

    shop = Shop.find_or_create_by(shopify_id: shopify.id, shopify_token: token)
    shop.update_attribute :shopify_attributes, shopify.attributes
    shop
  end

  def self.shopify_shop(shop, token)
    with_shopify_session(shop, token) do |session|
      session.shop
    end
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

  def generate_token
    self.token = Devise.friendly_token
  end
end
