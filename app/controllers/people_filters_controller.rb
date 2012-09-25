class PeopleFiltersController < CrudController
  
  self.nesting = Group
  
  decorates :people_filter, :group
  
  hide_action :index, :show, :edit, :update
  
  skip_authorize_resource only: :create
  
  # load group before authorization
  prepend_before_filter :parent

  def create
    if model_params[:name].blank?
      authorize!(:new, entry)
      redirect_to group_people_path(parent, model_params.slice(:kind, :role_types))
    else
      authorize!(:create, entry)
      super(location: group_people_path(parent, model_params))
    end
  end

  private
    
  def build_entry 
    filter = super
    filter.group_id = parent.id
    filter
  end
  
end