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
#  contact_id_id       :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  deleted_at          :datetime
#  bank_account        :string(255)
#  jubla_insurance     :boolean          default(FALSE), not null
#  jubla_full_coverage :boolean          default(FALSE), not null
#  parish              :string(255)
#  kind                :string(255)
#  unsexed             :boolean          default(FALSE), not null
#  clairongarde        :boolean          default(FALSE), not null
#  founding_year       :integer
#  coach_id            :belongs_to
#  advisor_id          :belongs_to
#

class Group < ActiveRecord::Base
  
  acts_as_nested_set
  acts_as_paranoid
  
  attr_accessible :parent_id, :name, :short_name, :email, :contact_id

  
  include Contactable
  
  has_many :roles
  has_many :people, through: :roles
  
  belongs_to :contact, class_name: 'Person'
  
  
  # The hierarchy from top to bottom of and including this group.
  def hierarchy
    @hierarchy ||= ancestors.order(:lft).to_a + [self]
  end
  
  # The layer of this group.
  def layer
    layers.last
  end
  
  # The layer hierarchy from top to bottom of this group.
  def layers
    hierarchy.select { |g| g.layer }
  end
  
  
  module Types
    extend ActiveSupport::Concern
    
    included do
      class_attribute :layer, :role_types, :possible_children, :default_children
      
      # Whether this group type builds a layer or is a regular group. Layers influence some permissions.
      self.layer = false
      # List of the role types that are available for this group type.
      self.role_types = []
      # Child group types that may be created for this group type.
      self.possible_children = []
      # Child groups that are automatically created with a group of this type.
      self.default_children = []
    end
    
    module ClassMethods
      def children(*group_types)
        self.possible_children = group_types + self.possible_children
      end
      
      def roles(*types)
        self.role_types = types + self.role_types
      end
    end
  end
  
  include Types
  
end
