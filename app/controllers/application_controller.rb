class ApplicationController < ActionController::Base
  protected
  def check_sign_in
    not_authorized unless user_signed_in?
  end

  def not_authorized
    render status: 401, json: { error: 'Not authorized.' }
  end

  def default_url_options(opts = {})
    opts.merge! tld_length: ENV['APP_HOST'].split('.').size - 1
    opts.merge! host: ENV['APP_HOST'], subdomain: false
    opts
  end
end
