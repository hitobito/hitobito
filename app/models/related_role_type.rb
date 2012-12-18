# == Schema Information
#
# Table name: related_role_types
#
#  id            :integer          not null, primary key
#  relation_id   :integer
#  role_type     :string(255)      not null
#  relation_type :string(255)
#

class RelatedRoleType < ActiveRecord::Base
  
  belongs_to :relation, polymorphic: true
  
  attr_accessible :role_type
  
  validates :role_type, inclusion: {in: lambda { |i| Role.all_types.collect(&:sti_name) } }
  
  def to_s
    role_type
  end
  
end
