class Superuser::UsersController < SuperuserController
  def index
    @users = User.all
  end
end
