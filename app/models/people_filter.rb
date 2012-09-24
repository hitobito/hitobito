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
    super || 'group'
  end
  
  def to_s
    name
  end
  
  class RoleType < ActiveRecord::Base
    belongs_to :people_filter
    
    attr_accessible :role_type, :group_type
    
    validates :role_type, inclusion: Role.all_types.collect(&:sti_name)
    validates :group_type, inclusion: Group.all_types.collect(&:sti_name), allow_nil: true
    
    def to_s
      role_type
    end
  end
end

