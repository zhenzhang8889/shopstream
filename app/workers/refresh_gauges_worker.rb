class RefreshGaugesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: true, expiration: 60

  def perform(shop_id)
    shop = Shop.find(shop_id)
    shop.refresh_gauges
  end
end
