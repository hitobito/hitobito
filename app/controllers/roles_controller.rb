class RolesController < CrudController
  
  self.nesting = Group
  
  decorates :role, :group
    
  # load group before authorization
  prepend_before_filter :parent
  
  hide_action :index, :show
  
  def create
    super(location: group_people_path(entry.group_id))
  end
  
  def update
    type = model_params && model_params.delete(:type)
    if type && type != entry.type 
      handle_type_change(type)
      redirect_to(group_person_path(entry.group_id, entry.person_id))
    else
      super(location: group_person_path(entry.group_id, entry.person_id))
    end
  end

  def destroy 
    super do |format|
      location = can?(:show, entry.person) ? person_path(entry.person_id) : group_path(parent)
      format.html { redirect_to(location) } 
    end
  end
  
  private 
  def handle_type_change(type)
    role = type.constantize.new
    role.initialize_dup(entry)
    role.save
    entry.destroy
    flash[:notice] = @@helper.t('roles.role_changed', old_role: full_entry_label, new_role: role).html_safe
    set_model_ivar(role)
  end
  
  def build_entry 
    if model_params.blank? || !parent.class.role_types.collect(&:sti_name).include?(model_params[:type])
      raise ActiveRecord::RecordNotFound 
    end

    # delete unused attributes
    model_params.delete(:group_id)
    model_params.delete(:person)
    
    role = model_params.delete(:type).constantize.new
    role.group_id = parent.id
    role.person_id = model_params.delete(:person_id)
    role
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label(role=entry)
    "#{models_label(false)} #{RoleDecorator.decorate(role).flash_info}".html_safe
  end
end
