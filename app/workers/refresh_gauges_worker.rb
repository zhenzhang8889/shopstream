class RefreshGaugesWorker
  include Sidekiq::Worker
  sidekiq_options unique: true, expiration: 60 * 1000

  def perform(shop_id)
    shop = Shop.find(shop_id)
    shop.refresh_gauges
  end
end
