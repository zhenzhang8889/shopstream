module V1
  class ShopsController < ApplicationController
    before_filter :check_sign_in

    def show
      @shop = Shop.find params[:id]

      return not_authorized unless current_user.shops.include?(@shop)

      render json: @shop
    end

    def update
      @shop = Shop.find params[:id]

      return not_authorized unless current_user.shops.include?(@shop)

      @shop.update_attributes params[:shop]

      render json: @shop
    end

    def create
      @shop = CustomShop.new params[:shop]
      @shop.user = current_user

      if @shop.save
        render json: @shop
      else
        render json: { errors: @shop.errors.full_messages }
      end
    end
  end
end
