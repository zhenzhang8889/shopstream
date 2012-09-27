class HomeController < ApplicationController
  before_filter :authenticate_user!

  def app
  end
end
