task send_daily_notifications: :environment do
  shops = Shop.interested_in_reports Time.now

  shops.each do |shop|
    ReportsMailer.daily(shop).deliver
  end  
end