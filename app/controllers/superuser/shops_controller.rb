class Superuser::ShopsController < SuperuserController
  def index
    @shops = Shop.page params[:page]
  end
end
