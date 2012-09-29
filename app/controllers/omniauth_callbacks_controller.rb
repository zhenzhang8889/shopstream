class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def shopify
    auth_data = request.env['omniauth.auth']
    shop_host = params['shop'].to_s

    return auth_error unless auth_data && shop_host

    shop = Shop.create_with_omniauth_and_user shop_host, auth_data.credentials.token, current_user

    return auth_error unless shop

    redirect_to after_shopify_auth_uri(user)
  end

  def after_shopify_auth_uri(user)
    root_url
  end

  def auth_error
    render status: 500, json: { error: 'Error while authenticating via Shopify.' }
  end
end
