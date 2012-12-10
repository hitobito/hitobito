class DashboardController < ApplicationController
  
  skip_before_filter :authenticate_person!, only: :index
  skip_authorization_check only: :index
  
  def index
    flash.keep
    if current_user
      redirect_to person_home_path(current_user)
    else
      redirect_to new_person_session_path
    end
  end
end