class ShopsController < ApplicationController
  before_filter :authenticate_superuser!, only: [:show]

  def connect
    if params[:shop].present?
      shop_url = params[:shop]
      url = URI.parse(shop_url)
      url = URI.parse("http://#{shop_url}") if url.scheme.nil?

      redirect_to "/auth/shopify?shop=#{url.host}"
    else
      redirect_to root_path
    end
  end

  def show
    @shop = Shop.find params[:id]

    sign_in :user, @shop.user

    redirect_to request.original_url.sub('manage.', '').sub('/shops/', '/#/shops/').concat "/dashboard"
  end
end
