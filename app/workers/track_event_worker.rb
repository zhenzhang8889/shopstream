class TrackEventWorker
  include Sidekiq::Worker

  def perform(shop_id, event, payload)
    shop = Shop.find(shop_id)
    shop.send("track_#{event}", payload)
  end
end
