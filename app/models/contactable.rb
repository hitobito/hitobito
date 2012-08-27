module Contactable
  
  extend ActiveSupport::Concern
  
  included do
    
    attr_accessible :email, :address, :zip_code, :town, :country
    
    has_many :phone_numbers, as: :contactable
    has_many :social_accounts, as: :contactable
    
  end
  
  
end