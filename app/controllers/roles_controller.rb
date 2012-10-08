class RolesController < CrudController
  
  self.nesting = Group
  
  decorates :role, :group
  
  skip_authorize_resource only: [:index, :show]
  skip_authorization_check only: [:index, :show]
  
  # load group before authorization
  prepend_before_filter :parent
  
  hide_action :index, :show
  
  def create
    super(location: group_people_path(entry.group_id))
  end
  
  def update
    super(location: group_person_path(entry.group_id, entry.person_id))
  end
  
  def destroy
    super(location: person_path(entry.person_id))
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

  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    "#{models_label(false)} #{RoleDecorator.decorate(entry).flash_info}".html_safe
  end
end
