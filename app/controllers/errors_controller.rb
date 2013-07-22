class ErrorsController < ActionController::Base
  layout 'application'
  helper_method :current_user

  private

  def current_user
    false
  end
end
