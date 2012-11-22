task send_daily_notifications: :environment do
  shops = Shop.interested_in_reports Time.now

  shops.each do |shop|
    ReportsMailer.daily(shop).deliver
  end  

  users = User.interested_in_no_store_notification

  users.each do |user|
    ReportsMailer.no_store(user, user.days_since_signup).deliver
  end
end
