# Used to generate static error pages with the application layout:
# RAILS_GROUPS=assets rails generate error_page {status}
class ErrorsController < ActionController::Base
  layout 'application'
  helper_method :current_user

  private

  def current_user
    false
  end
end
