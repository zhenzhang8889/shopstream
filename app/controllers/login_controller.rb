class LoginController < ApplicationController
  def authenticate
    if params[:shop].present?
      shop_url = params[:shop]
      url = URI.parse(shop_url)
      url = URI.parse("http://#{shop_url}") if url.scheme.nil?

      if params[:charge_id].present?
        Shop.activate_shopify_recurring_charge(url.host, params[:charge_id])
      end

      redirect_to "/auth/shopify?shop=#{url.host}"
    else
      redirect_to root_path
    end
  end
end
