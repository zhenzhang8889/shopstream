class Superuser::DashboardController < SuperuserController
  def show
    @active_shop_count = Shop.active.count
    @inactive_shop_count = Shop.inactive.count
    @never_tracked_count = Shop.never_tracked.count
    @user_count = User.count
  end
end
