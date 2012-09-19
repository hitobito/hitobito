class GroupsController < CrudController
  
  skip_authorize_resource only: :index
  skip_authorization_check only: :index

  decorates :group, :groups
  prepend_before_filter :ability_for_create, only: [:new, :create]
  
  self.ability_types = {with_group: :all}

  before_render_form :load_contacts

  def index
    flash.keep
    redirect_to Group.root
  end
  

  private 
  
  def build_entry 
    group = model_params.delete(:type).constantize.new
    group.parent_id = model_params.delete(:parent_id)
    group
  end

  def assign_attributes 
    role = can?(:modify_superior, entry) ? :superior : :default
    entry.assign_attributes(model_params, as: role)
  end


  def load_contacts
    @contacts = entry.people.external(false).only_public_data.order_by_name
  end

  def ability_for_create
    @current_ability = Ability::WithGroup.new(current_user, entry.parent)
  end
end
