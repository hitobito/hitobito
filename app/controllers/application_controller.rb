class ApplicationController < ActionController::Base
  
  include DisplayCase::ExhibitsHelper

  class_attribute :ability_types
  
  protect_from_forgery
  helper_method :current_user
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => "Sie sind nicht berechtigt, diese Seite anzuzeigen"
  end
  
  before_filter :authenticate_person!
  check_authorization :unless => :devise_controller?
  
  
  private
  
  def current_user
    current_person
  end
  
  def current_ability
    @current_ability ||= create_ability
  end
  
  def create_ability
    type = :plain
    if ability_types
      type_list = ability_types.detect do |t, actions|
        actions == :all || actions.include?(action_name.to_sym)
      end
      type = type_list.first if type_list
    end
    send(:"ability_#{type}")
  end
  
  def ability_with_group
    Ability::WithGroup.new(current_user, @group)
  end
  
  def ability_plain
    Ability::Plain.new(current_user)
  end
end
