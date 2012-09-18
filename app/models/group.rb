# == Schema Information
#
# Table name: groups
#
#  id                  :integer          not null, primary key
#  parent_id           :integer
#  lft                 :integer
#  rgt                 :integer
#  name                :string(255)      not null
#  short_name          :string(31)
#  type                :string(255)      not null
#  email               :string(255)
#  address             :string(1024)
#  zip_code            :integer
#  town                :string(255)
#  country             :string(255)
#  contact_id          :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  deleted_at          :datetime
#  layer_group_id      :integer
#  bank_account        :string(255)
#  jubla_insurance     :boolean          default(FALSE), not null
#  jubla_full_coverage :boolean          default(FALSE), not null
#  parish              :string(255)
#  kind                :string(255)
#  unsexed             :boolean          default(FALSE), not null
#  clairongarde        :boolean          default(FALSE), not null
#  founding_year       :integer
#  coach_id            :integer
#  advisor_id          :integer
#

class Group < ActiveRecord::Base
  
  acts_as_nested_set
  acts_as_paranoid
  
  include Group::Types
  include Contactable
  
  
  ### ATTRIBUTES
  
  attr_accessible :name, :short_name, :email, :contact_id

  attr_readonly :type


  ### CALLBACKS
  
  after_create :set_layer_group_id
  after_create :create_default_children
  
  # Root group may not be destroyed
  protect_if :root?
  
  
  ### ASSOCIATIONS
  
  has_many :roles, dependent: :destroy
  has_many :people, through: :roles
  
  belongs_to :contact, class_name: 'Person'
  
  
  ### VALIDATIONS
  
  validate :assert_type_is_allowed_for_parent, on: :create
  
  
  ### CLASS METHODS
  
  class << self
    
    # Is the given attribute used in the current STI class
    def attr_used?(attr)
      [:default, :superior].any? do |role|
        accessible_attributes(role).include?(attr)
      end
    end

    def superior_attributes
      accessible_attributes(:superior).to_a - accessible_attributes(:default).to_a
    end

  end
  
  
  ### INSTANCE METHODS
  
  
  # The hierarchy from top to bottom of and including this group.
  def hierarchy
    @hierarchy ||= self_and_ancestors
  end
  
  # The layer of this group.
  def layer_group
    layer ? self : layer_groups.last
  end
  
  # The layer hierarchy from top to bottom of this group.
  def layer_groups
    hierarchy.select { |g| g.class.layer }
  end
  
  def to_s
    name
  end
  
  private
  
  def assert_type_is_allowed_for_parent
    if type && parent && !parent.possible_children.collect(&:to_s).include?(type)
      errors.add(:type, :type_not_allowed) 
    end 
  end

  def set_layer_group_id
    layer_group_id = self.class.layer ? id : parent.layer_group_id
    update_column(:layer_group_id, layer_group_id)
  end
  
  def create_default_children
    default_children.each do |group_type|
      child = group_type.new(name: group_type.model_name.human)
      child.parent = self
      child.save!
    end
  end
  
  
end
