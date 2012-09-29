class SuperuserController < ApplicationController
  layout 'superuser'

  before_filter :authenticate_superuser!

  protect_from_forgery

  def default_url_options(opts = {})
    opts.merge! tld_length: ENV['APP_HOST'].split('.').size - 1
    opts.merge! host: ENV['APP_HOST'], subdomain: 'manage'
    opts
  end
end
