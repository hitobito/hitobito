class PeopleFiltersController < CrudController
  
  self.nesting = Group
  
  decorates :group
  
  hide_action :index, :show, :edit, :update
  
  skip_authorize_resource only: :create
  
  # load group before authorization
  prepend_before_filter :parent
  
  before_render_form :compose_role_lists

  def create
    if params[:button] == 'save'
      authorize!(:create, entry)
      super(location: group_people_path(group, model_params))
    else
      authorize!(:new, entry)
      redirect_to group_people_path(group, model_params.slice(:kind, :role_types))
    end
  end
  
  def destroy
    super(location: group_people_path(group))
  end

  private
  
  alias_method :group, :parent
    
  def build_entry 
    filter = super
    filter.group_id = group.id
    filter
  end
  
  def compose_role_lists
    @role_types = Role::TypeList.new(group.layer_group.class)
  end
end