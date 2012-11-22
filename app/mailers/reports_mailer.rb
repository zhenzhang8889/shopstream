class ReportsMailer < ActionMailer::Base
  default from: "reports@#{ENV['APP_HOST']}"

  def daily(shop)
    @shop = shop

    mail to: shop.user.email, subject: 'Your Sales Report is Here! - [ShopStream]'
  end

  def no_store(user, days_since_signup)
    @user = user
    @days_since_signup = days_since_signup

    mail to: user.email, subject: 'No store created'
  end
end
