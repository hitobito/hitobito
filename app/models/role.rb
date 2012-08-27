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
  
  class_attribute :permissions, :visible_from_above, :external
  self.permissions = []
  self.visible_from_above = true
  self.external = false
  
  
  acts_as_paranoid
  
  attr_accessible :label
  
  belongs_to :person
  belongs_to :group
  
end
