module V1
  class UsersController < ApplicationController
    before_filter :check_sign_in

    def me
      @user = current_user

      authorize! :read, @user

      render json: @user
    end

    def show
      @user = User.find params[:id]

      authorize! :read, @user

      render json: @user
    end
  end
end
