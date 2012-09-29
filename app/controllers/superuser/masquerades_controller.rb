class Superuser::MasqueradesController < SuperuserController
  def new
    @user = User.find params[:user_id]
    sign_in :user, @user
    redirect_to root_url(subdomain: false)
  end

  def destroy
    sign_out :user
    redirect_to root_url(subdomain: 'manage')
  end
end
