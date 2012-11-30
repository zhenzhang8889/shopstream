class Superuser::UsersController < SuperuserController
  def index
    @users = User.page params[:page]
  end

  def show
    @user = User.find params[:id]
    @shops = @user.shops
  end
end
