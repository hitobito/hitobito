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
  
  has_many :people_filter_role_types, class_name: 'PeopleFilter::RoleType', dependent: :destroy
  
  validates :name, uniqueness: {scope: [:group_id, :group_type]}
  validates :kind, inclusion: %w(group layer deep)


  default_scope order(:name).includes(:people_filter_role_types)
  
  
  def role_types
    @role_types ||= people_filter_role_types.collect(&:to_s)
  end
  
  def role_types=(types)
    @role_types = types
    self.people_filter_role_types = types.collect {|t| RoleType.new(role_type: t) }
  end
  
  def kind
    super || 'deep'
  end
  
  def to_s
    name
  end
  
  class RoleType < ActiveRecord::Base
    belongs_to :people_filter
    
    attr_accessible :role_type
    
    validates :role_type, inclusion: {in: lambda { |i| Role.all_types.collect(&:sti_name) } }
    
    def to_s
      role_type
    end
  end
end

