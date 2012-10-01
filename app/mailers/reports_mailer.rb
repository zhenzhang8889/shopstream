class ReportsMailer < ActionMailer::Base
  default from: "reports@#{ENV['APP_HOST']}"

  def daily(shop)
    @shop = shop

    mail to: shop.user.email
  end
end
