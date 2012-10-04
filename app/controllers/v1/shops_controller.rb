module V1
  class ShopsController < ApplicationController
    before_filter :check_sign_in

    def index
      @shops = current_user.shops

      render json: @shops
    end

    def show
      @shop = Shop.find params[:id]

      authorize! :read, @shop

      render json: @shop
    end

    def update
      @shop = Shop.find params[:id]

      authorize! :update, @shop

      @shop.update_attributes params[:shop]

      render json: @shop
    end

    def create
      @shop = CustomShop.new params[:shop]
      @shop.user = current_user

      authorize! :create, @shop

      if @shop.save
        render json: @shop
      else
        render json: { errors: @shop.errors.full_messages },
          status: :unprocessable_entity
      end
    end

    def destroy
      @shop = Shop.find params[:id]

      authorize! :destroy, @shop

      @shop.destroy

      head :ok
    end
  end
end
