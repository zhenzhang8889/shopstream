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

    billing_confirmation_url = shop.setup_shopify_billing(login_url(shop: shop.domain))

    if billing_confirmation_url
      redirect_to billing_confirmation_url
    else
      redirect_to after_shopify_auth_uri(user)
    end
  end

  def after_shopify_auth_uri(user)
    "http://#{ENV['FRONTEND_HOST']}/auth-callback/?accessToken=#{user.authentication_token}"
  end

  def auth_error
    render status: 500, json: { error: 'Error while authenticating via Shopify.' }
  end
end
