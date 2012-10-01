# encoding: UTF-8
require_dependency Devise::Engine.root.join('app', 'controllers','devise', 'passwords_controller').to_s
class Devise::PasswordsController < DeviseController
  def successfully_sent?(resource)
    return super if resource.login?
    flash[:alert] = "Du kannst kein Passwort nicht zurücksetzen lassen."
  end
end
