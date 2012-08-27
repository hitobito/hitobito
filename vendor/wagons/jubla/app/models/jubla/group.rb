module Jubla::Group
  extend ActiveSupport::Concern
  
  included do
    # define roles before children
    roles Jubla::Role::GroupAdmin, 
          Jubla::Role::Contact, 
          Jubla::Role::External
          
    children Group::SimpleGroup
    
    attr_accessible :bank_account
  end
  
end