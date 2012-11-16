require 'spec_helper'

describe ShopifyShop do
  let(:shop) { FactoryGirl.create :shopify_shop }
  subject { shop }

  it { should validate_presence_of(:shopify_id) }
  it { should validate_uniqueness_of(:shopify_id) }
  it { should validate_presence_of(:shopify_token) }

  describe '#extract_shopify_attributes' do
    it 'extracts domain' do
      shop.shopify_attributes['domain'] = 'some-domain.tld'
      expect { shop.extract_shopify_attributes }.to change { shop.domain }.to 'some-domain.tld'
    end

    it 'extracts name' do
      shop.shopify_attributes['name'] = 'Da Shop'
      expect { shop.extract_shopify_attributes }.to change { shop.name }.to 'Da Shop'
    end

    it 'extracts timezone' do
      shop.shopify_attributes['timezone'] = '(UTC-5) Indiana (East)'
      expect { shop.extract_shopify_attributes }.to change { shop.timezone }.to 'Indiana (East)'
    end
  end

  describe '#shopify_shop' do
    it 'gets a Shopify::Shop for current shop' do
      ShopifyShop.should_receive(:shopify_shop).with(shop.domain, shop.shopify_token)
      shop.shopify_shop
    end
  end

  describe '#setup_shopify_shop'

  describe '#setup_shopify_script_tag' do
    it 'sets up tracker script' do
      ShopifyAPI::ScriptTag.should_receive(:create).with(src: shop.tracker_script_url, event: 'onload')
      shop.setup_shopify_script_tag
    end
  end

  describe '#setup_shopify_webhooks' do
    it 'sets up hooks' do
      shop.should_receive(:setup_shopify_webhook).with('orders/create', :new_order)
      shop.should_receive(:setup_shopify_webhook).with('carts/create', :new_cart)
      shop.should_receive(:setup_shopify_webhook).with('carts/update', :updated_cart)
      shop.should_receive(:setup_shopify_webhook).with('app/uninstalled', :app_uninstalled)

      shop.setup_shopify_webhooks
    end
  end

  describe '#setup_shopify_billing'

  describe '#with_shopify_session'

  describe '.shopify_shop'

  describe '.with_shopify_session'

  describe '.create_with_omniauth_and_user'
end
