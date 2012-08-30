# == Schema Information
#
# Table name: roles
#
#  id                 :integer          not null, primary key
#  person_id          :integer          not null
#  group_id           :integer          not null
#  type               :string(255)      not null
#  label              :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  deleted_at         :datetime
#  employment_percent :integer
#  honorary           :boolean
#

class Role < ActiveRecord::Base
  
  acts_as_paranoid
  
  attr_accessible :label
  
  belongs_to :person
  belongs_to :group
  
  validate :assert_type_is_allowed_for_group, on: :create
  
  def to_s
    label.presence || self.class.model_name.human
  end
  
  
  private
  
  def assert_type_is_allowed_for_group
    if type && group && !group.role_types.collect(&:to_s).include?(type)
      errors.add(:type, :type_not_allowed)
    end 
  end
  
  module Types
    extend ActiveSupport::Concern
    
    included do
      class_attribute :permissions, :visible_from_above, :external
      self.permissions = []
      self.visible_from_above = true
      self.external = false
    end
    
    module ClassMethods
      def all_types
        @all_types ||= Group.all_types.collect(&:role_types).flatten.uniq
      end
      
      def visible_types
        all_types.select(&:visible_from_above)
      end
    end
  end
  
  include Types
  
end
