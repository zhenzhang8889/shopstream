class RefreshGaugesWorker
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform(shop_id)
    shop = Shop.find(shop_id)
    shop.refresh_gauges
  end
end
