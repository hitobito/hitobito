class RolesController < CrudController
  
  self.nesting = Group
  self.ability_types = {with_group: [:new, :create]}
  
  # load group before authorization
  prepend_before_filter :parent
  
  # TODO redirects after save
  
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