module Contactable
  
  extend ActiveSupport::Concern
  
  included do
    
    attr_accessible :email, :address, :zip_code, :town, :country
    
    has_many :phone_numbers, as: :contactable, dependent: :destroy
    has_many :social_accounts, as: :contactable, dependent: :destroy
    
    scope :public_accounts, select(%w(phone_numbers.number 
                                      phone_numbers.label 
                                      social_accounts.name 
                                      social_accounts.label)).
                            joins("LEFT OUTER JOIN phone_numbers ON " +
                                    "phone_numbers.contactable_id = #{table_name}.id AND " + "
                                     phone_numbers.contactable_type = '#{name}' " +
                                  "LEFT OUTER JOIN social_accounts ON " +
                                    "social_accounts.contactable_id = #{table_name}.id AND " +
                                    "social_accounts.contactable_type = '#{name}'").
                            where(phone_numbers: {public: true}, 
                                  social_accounts: {public: true})
    
  end
  
  
end