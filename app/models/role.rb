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
  
  include Role::Types
  
  attr_accessible :label
  
  # If these attributes should change, create a new role instance instead.
  attr_readonly :person_id, :group_id, :type
  
  ### ASSOCIATIONS
  
  belongs_to :person
  belongs_to :group
  
  
  ### VALIDATIONS
  
  validates :type, presence: true
  validate :assert_type_is_allowed_for_group, on: :create
  
  
  ### CALLBACKS
  
  after_create :set_contact_data_visible
  after_destroy :reset_contact_data_visible

  # TODO create person login if this role type has login permission; validate email presence first
  
    
  
  ### CLASS METHODS
  
  class << self
    
    # Is the given attribute used in the current STI class
    def attr_used?(attr)
      [:default, :superior].any? do |role|
        accessible_attributes(role).include?(attr)
      end
    end
  end
  
  
  ### INSTANCE METHODS
  
  def to_s
    label.presence || self.class.model_name.human
  end
  
  
  private
  
  # If this role has contact_data permissions, set the flag on the person
  def set_contact_data_visible
    if becomes(type.constantize).permissions.include?(:contact_data)
      person.update_attribute :contact_data_visible, true
    end
  end
  
  # If this role was the last one with contact_data permission, remove the flag from the person
  def reset_contact_data_visible
    if permissions.include?(:contact_data) && 
       !person.roles.collect(&:permissions).flatten.include?(:contact_data)
      person.update_attribute :contact_data_visible, false
    end
  end
  
  def assert_type_is_allowed_for_group
    if type && group && !group.role_types.collect(&:sti_name).include?(type)
      errors.add(:type, :type_not_allowed)
    end 
  end
  
end
