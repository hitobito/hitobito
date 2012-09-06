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
  
  belongs_to :person
  belongs_to :group
  
  validate :assert_type_is_allowed_for_group, on: :create
  
  # TODO set contact_data_visible in person on create / destroy
  # TODO create person login if this role type has login permission; validate email presence first
  
  def to_s
    label.presence || self.class.model_name.human
  end
  
  
  private
  
  def assert_type_is_allowed_for_group
    if type && group && !group.role_types.collect(&:to_s).include?(type)
      errors.add(:type, :type_not_allowed)
    end 
  end
  
end
