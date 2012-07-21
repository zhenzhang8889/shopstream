class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def shopify
    auth_data = request.env['omniauth.auth']
    shop_host = params['shop'].to_s

    return auth_error unless auth_data && shop_host

    shop = Shop.find_or_create_with_omniauth shop_host, auth_data.credentials.token

    return auth_error unless shop

    if shop.user
      user = shop.user
    else
      user = User.create
      user.shop = shop
      user.save
    end

    redirect_to after_shopify_auth_uri(user)
  end

  def after_shopify_auth_uri(user)
    "http://#{ENV['FRONTEND_HOST']}/auth-callback/?accessToken=#{user.authentication_token}"
  end

  def auth_error
    render status: 500, json: { error: 'Error while authenticating via Shopify.' }
  end
end
