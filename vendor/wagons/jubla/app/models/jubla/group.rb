module Jubla::Group
  extend ActiveSupport::Concern
  
  included do
    class_attribute :contact_group_type

    attr_accessible :bank_account

    has_many :course_conditions, class_name: '::Event::Course::Condition', dependent: :destroy
    
    # define global roles before children
    roles Jubla::Role::GroupAdmin, 
          Jubla::Role::External,
          Jubla::Role::Alumnus
          
    # define global children
    children Group::SimpleGroup
    
    root_types Group::Federation
  end
  
  def census?
    respond_to?(:census_total)
  end
end
