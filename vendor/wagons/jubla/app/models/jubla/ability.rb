module Jubla::Ability
  extend ActiveSupport::Concern
  
  
  included do
    alias_method_chain :initialize, :jubla
  end
  
  def initialize_with_jubla(user)
    initialize_without_jubla(user)
  end

  def can_update_event?(event)
    # courses require admin flag to be updated once they are in the state closed
    can_update = event.kind_of?(Event::Course) && event.state == 'closed' ? admin : true
    can_update && can_manage_event?(event)
  end

  
end
