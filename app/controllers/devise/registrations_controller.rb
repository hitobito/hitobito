require_dependency Devise::Engine.root.join('app', 'controllers','devise', 'registrations_controller').to_s

class Devise::RegistrationsController < DeviseController
  
  before_filter :has_old_password, only: [:edit, :update]
  before_filter :reject_non_password_params, only: [:update]

  private
  
  # this controller writes all person attributes, we use it to change the password
  # therefore we reject all but the password param
  def reject_non_password_params
    params[:person].select! { |key| key =~ /password/ }
  end
  
  def has_old_password
    @old_password = resource.encrypted_password?
  end
end
