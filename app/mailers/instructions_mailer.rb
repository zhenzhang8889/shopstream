class InstructionsMailer < ActionMailer::Base
  default from: "reports@#{ENV['APP_HOST']}"

  def instructions(shop, developer)
    @shop = shop

    mail to: developer, subject: 'Help set up the shop'
  end
end
