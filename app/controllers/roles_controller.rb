class RolesController < CrudController
  
  self.nesting = Group
  self.ability_types = {with_group: [:new, :create]}
  
  # load group before authorization
  prepend_before_filter :parent
  
  private 
  
  def build_entry 
    role = model_params.delete(:type).constantize.new
    role.group_id = parent.id
    role
  end

end