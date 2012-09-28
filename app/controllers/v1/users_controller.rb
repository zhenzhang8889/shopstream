module V1
  class UsersController < ApplicationController
    before_filter :check_sign_in

    def me
      @user = current_user

      render json: @user
    end

    def show
      @user = User.find params[:id]

      return not_authorized unless @user == current_user

      render json: @user
    end
  end
end
