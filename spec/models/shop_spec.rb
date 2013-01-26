require 'spec_helper'

describe Shop do
  let(:shop) { FactoryGirl.create :shop }
  subject { shop }

  it { should belong_to(:user) }
  it { should have_many(:feed_items) }
  it { should validate_uniqueness_of(:token) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:domain) }
  it { should validate_presence_of(:timezone) }
  it { should validate_inclusion_of(:timezone).to_allow('UTC') }

  describe '#tz' do
    it 'creates TimeZone object' do
      expect(shop.tz).to eq ActiveSupport::TimeZone.new 'UTC'
    end
  end

  describe '#tracker_script_url' do
    it 'generates tracker script URL based on token' do
      expect(shop.tracker_script_url).to eq "https://collector.shopstream.dev/track-#{shop.token}.js"
    end
  end

  describe '#webhook_url' do
    it 'generates webhook url based on token and action' do
      expect(shop.webhook_url(:stuff)).to eq "http://collector.shopstream.dev/webhooks/shopify/#{shop.token}/stuff"
    end
  end

  describe '#ever_tracked?' do
    context 'never tracked' do
      it 'returns false' do
        shop.stub last_tracked_at: nil
        expect(shop.ever_tracked?).to eq false
      end
    end

    context 'tracked' do
      it 'returns true' do
        shop.stub last_tracked_at: 1.hour.ago
        expect(shop.ever_tracked?).to eq true
      end
    end
  end

  describe '#tracked_recently?' do
    context 'tracked less than 24 hours ago' do
      it 'returns true' do
        shop.stub last_tracked_at: 1.hour.ago
        expect(shop.tracked_recently?).to eq true
      end
    end

    context 'tracker more than 24 hours ago' do
      it 'returns false' do
        shop.stub last_tracked_at: 25.hours.ago
        expect(shop.tracked_recently?).to eq false
      end
    end
  end

  describe '#generate_token' do
    it 'calls Devise.friendly_token' do
      Devise.should_receive(:friendly_token).at_least(1)
      shop.generate_token
    end

    it 'changes token' do
      expect { shop.generate_token }.to change { shop.token }
    end
  end
end
