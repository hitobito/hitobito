# encoding: UTF-8
require_dependency Devise::Engine.root.join('app', 'controllers','devise', 'passwords_controller').to_s

class Devise::PasswordsController < DeviseController
  
  def successfully_sent?(resource)
    if resource.login?
      super
    else 
      flash[:alert] = "Du bist nicht berechtigt, Dich hier anzumelden."
    end
  end
  
end
