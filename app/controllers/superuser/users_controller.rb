class Superuser::UsersController < SuperuserController
  def index
    @users = User.page params[:page]
  end
end
