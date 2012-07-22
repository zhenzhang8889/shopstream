module V1
  class UsersController < ApplicationController
    before_filter :check_sign_in

    respond_to :json

    def me
      @user = current_user

      render action: :show
    end

    def show
      @user = User.find params[:id]

      return not_authorized unless @user == current_user

      respond_with @user
    end
  end
end
