module V1
  class ShopsController < ApplicationController
    before_filter :check_sign_in

    respond_to :json

    def my
      @shop = current_user.shop

      render action: :show
    end

    def show
      @shop = Shop.find params[:id]

      return not_authorized unless @shop == current_user.shop

      respond_with @shop
    end
  end
end
