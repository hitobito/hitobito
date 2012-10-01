module Jubla::Ability
  extend ActiveSupport::Concern
  
  
  included do
    alias_method_chain :initialize, :jubla
  end
  
  def initialize_with_jubla(user)
    initialize_without_jubla(user)
    
    
  end
  
  
end