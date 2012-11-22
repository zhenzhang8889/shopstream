class InstructionsMailer < ActionMailer::Base
  default from: "reports@#{ENV['APP_HOST']}"

  def instructions(shop, developer)
    @shop = shop

    @to_self = @shop.user.email == developer
    subject = @to_self ? 'Shop setup instructions' : "Help #{@shop.user.name} set up the shop"

    mail to: developer, subject: subject
  end
end
