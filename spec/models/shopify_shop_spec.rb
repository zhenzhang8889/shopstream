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

  describe '#with_shopify_session' do
    it 'callcs .with_shopify_session' do
      ShopifyShop.should_receive(:with_shopify_session).with shop.domain, shop.shopify_token
      shop.with_shopify_session do; end
    end
  end

  describe '.shopify_shop' do
    it 'creates session' do
      ShopifyAPI::Session.should_receive(:temp).with shop.domain, shop.token
      ShopifyShop.shopify_shop shop.domain, shop.token
    end

    it 'gets current shop' do
      ShopifyAPI::Shop.should_receive :current
      ShopifyShop.shopify_shop shop.domain, shop.token
    end
  end

  describe '.with_shopify_session' do
    it 'creates session' do
      ShopifyAPI::Session.should_receive(:temp).with shop.domain, shop.token
      ShopifyShop.with_shopify_session shop.domain, shop.token do; end
    end
  end

  describe '.create_with_omniauth_and_user' do
    context 'shop is invalid' do
      before { ShopifyShop.stub shopify_shop: nil }

      it 'returns nil' do
        expect(ShopifyShop.create_with_omniauth_and_user(shop.domain, 'abc', shop.user)).to eq nil
      end
    end

    context 'shop is valid' do
      before { ShopifyShop.stub shopify_shop: double('shopify-api-shop').as_null_object }
      let(:mock_shop) { double('shop', save: true).as_null_object }

      it 'creates shopify shop' do
        ShopifyShop.should_receive(:new).at_least(1).and_return mock_shop
        ShopifyShop.create_with_omniauth_and_user shop.domain, 'abc', shop.user
      end

      it 'assigns the user' do
        ShopifyShop.should_receive(:new).at_least(1).and_return mock_shop
        mock_shop.should_receive(:user=).with shop.user

        ShopifyShop.create_with_omniauth_and_user shop.domain, 'abc', shop.user
      end

      it 'extracts attributes' do
        ShopifyShop.should_receive(:new).at_least(1).and_return mock_shop
        mock_shop.should_receive(:extract_shopify_attributes)

        ShopifyShop.create_with_omniauth_and_user shop.domain, 'abc', shop.user
      end

      it 'saves' do
        ShopifyShop.should_receive(:new).at_least(1).and_return mock_shop
        mock_shop.should_receive(:save)

        ShopifyShop.create_with_omniauth_and_user shop.domain, 'abc', shop.user
      end

      it 'sets up shopify stuff' do
        ShopifyShop.should_receive(:new).at_least(1).and_return mock_shop
        mock_shop.should_receive(:setup_shopify_shop)

        ShopifyShop.create_with_omniauth_and_user shop.domain, 'abc', shop.user
      end

      it 'returns shop' do
        ShopifyShop.should_receive(:new).at_least(1).and_return mock_shop

        expect(ShopifyShop.create_with_omniauth_and_user(shop.domain, 'abc', shop.user)).to eq mock_shop
      end
    end
  end
end
