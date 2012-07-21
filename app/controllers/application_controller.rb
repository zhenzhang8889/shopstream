class ApplicationController < ActionController::Base
  protected
  def check_sign_in
    not_authorized unless user_signed_in?
  end

  def not_authorized
    render status: 401, json: { error: 'Not authorized.' }
  end
end
