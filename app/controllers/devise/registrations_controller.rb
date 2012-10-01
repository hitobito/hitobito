require_dependency Devise::Engine.root.join('app', 'controllers','devise', 'registrations_controller').to_s

class Devise::RegistrationsController < DeviseController
  before_filter :reject_non_password_params, only: [:update]

  # this controller writes all person attributes, we use it to change the password
  # therefore we reject all but the password param
  def reject_non_password_params
    params[:person].select! { |key| key =~ /password/ }
  end
end
