module Jubla::Group
  extend ActiveSupport::Concern
  
  included do
    # define global roles before children
    roles Jubla::Role::GroupAdmin, 
          Jubla::Role::External
          
    # define global children
    children Group::SimpleGroup
    
    roots << Group::Federation
    
    attr_accessible :bank_account
  end
  
end