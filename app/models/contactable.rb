module Contactable
  
  extend ActiveSupport::Concern
  
  included do
    
    attr_accessible :email, :address, :zip_code, :town, :country
    
    has_many :phone_numbers, as: :contactable, dependent: :destroy
    has_many :social_accounts, as: :contactable, dependent: :destroy
    
    scope :preload_accounts, includes(:phone_numbers, :social_accounts)
    scope :preload_public_accounts, scoped.extending(Person::PreloadPublicAccounts)
    
  end

  
end