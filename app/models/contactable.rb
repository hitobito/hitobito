module Contactable
  
  extend ActiveSupport::Concern
  
  included do
    
    attr_accessible :email, :address, :zip_code, :town, :country,
                    :phone_numbers_attributes, :social_accounts_attributes
    
    has_many :phone_numbers, as: :contactable, dependent: :destroy
    has_many :social_accounts, as: :contactable, dependent: :destroy
    
    scope :preload_accounts, includes(:phone_numbers, :social_accounts)
    scope :preload_public_accounts, scoped.extending(Person::PreloadPublicAccounts)

    accepts_nested_attributes_for :phone_numbers, :social_accounts
    
  end

  
end
