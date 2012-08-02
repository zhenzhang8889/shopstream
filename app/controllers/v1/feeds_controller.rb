module V1
  class FeedsController < ApplicationController
    before_filter :check_sign_in

    respond_to :json

    def show
      @shop = Shop.find params[:shop_id]

      return not_authorized unless @shop == current_user.shop

      @feed = @shop.feed_items.limit(10).to_a

      respond_with @feed
    end
  end
end
