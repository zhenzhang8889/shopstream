module V1
  class ShopsController < ApplicationController
    before_filter :check_sign_in

    def my
      @shop = current_user.shop

      render json: @shop
    end

    def show
      @shop = Shop.find params[:id]

      return not_authorized unless @shop == current_user.shop

      render json: @shop
    end
  end
end
