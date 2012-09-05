class ApplicationController < ActionController::Base
  protect_from_forgery
  
  # TODO load current_user with preload_groups
  
  # TODO 
  #before_filter :authenticate_user!

  # TODO
  #check_authorization :unless => :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end
end
