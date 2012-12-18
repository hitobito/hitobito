# == Schema Information
#
# Table name: people_filters
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  group_id   :integer
#  group_type :string(255)
#  kind       :string(255)      not null
#

class PeopleFilter < ActiveRecord::Base
  
  attr_accessible :name, :kind, :role_types
  
  
  belongs_to :group
  
  has_many :related_role_types, as: :relation, dependent: :destroy
  
  validates :name, uniqueness: {scope: [:group_id, :group_type]}
  validates :kind, inclusion: %w(group layer deep)


  default_scope order(:name).includes(:related_role_types)
  
  
  def role_types
    @role_types ||= related_role_types.collect(&:to_s)
  end
  
  def role_types=(types)
    @role_types = Array(types.presence)
    self.related_role_types = @role_types.collect {|t| RelatedRoleType.new(role_type: t) }
  end
  
  def kind
    super.presence || 'deep'
  end
  
  def to_s
    name
  end
  
  class << self
    def for_group(group)
      where("group_id = ? OR group_type = ? OR (group_id IS NULL AND group_type IS NULL)", group.id, group.type)
    end
  end
  
end

