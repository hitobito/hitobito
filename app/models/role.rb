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
  
  before_save :normalize_label
  after_create :set_contact_data_visible
  after_create :send_password_if_first_login_role
  after_destroy :reset_contact_data_visible

  
  ### CLASS METHODS
  
  class << self
    
    # Is the given attribute used in the current STI class
    def attr_used?(attr)
      [:default, :superior].any? do |role|
        accessible_attributes(role).include?(attr)
      end
    end
    
    def available_labels
      @available_labels ||= order(:label).uniq.pluck(:label).compact
    end
    
    def sweep_available_labels
      @available_labels = nil
    end
  end
  
  
  ### INSTANCE METHODS
  
  def to_s
    label.presence || self.class.model_name.human
  end
  
  
  private
  
  # If a case-insensitive same label already exists, use this one
  def normalize_label
    return if label.blank?
    fresh = self.class.available_labels.none? do |l|
      equal = l.casecmp(label) == 0
      self.label = l if equal
      equal
    end
    self.class.sweep_available_labels if fresh
  end
  
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
  
  def send_password_if_first_login_role
    if becomes(type.constantize).permissions.include?(:login) && person.encrypted_password.blank?
      person.send_reset_password_instructions
    end
  end
  
  def assert_type_is_allowed_for_group
    if type && group && !group.role_types.collect(&:sti_name).include?(type)
      errors.add(:type, :type_not_allowed)
    end 
  end
  
end
