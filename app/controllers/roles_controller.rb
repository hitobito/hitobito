class RolesController < CrudController
  
  self.nesting = Group
  self.ability_types = {with_group: [:new, :create]}
  
  decorates :role, :group
  
  skip_authorize_resource only: [:index, :show]
  skip_authorization_check only: [:index, :show]
  
  # load group before authorization
  prepend_before_filter :parent
  
  
  def index
    redirect_to group_people_path(@group)
  end
  
  def show
    redirect_to group_person_path(entry.group_id, entry.person_id)
  end
    
  def create
    super(location: group_people_path(entry.group_id))
  end
  
  def update
    super(location: group_person_path(entry.group_id, entry.person_id))
  end
  
  private 
  
  def build_entry 
    # delete unused attributes
    model_params.delete(:group_id)
    model_params.delete(:person)
    
    role = model_params.delete(:type).constantize.new
    role.group_id = parent.id
    role.person_id = model_params.delete(:person_id)
    role
  end

end