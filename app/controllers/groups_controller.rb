class GroupsController < CrudController
  
  decorates :group, :groups, :contact
  
  before_render_show :load_contact
  before_render_form :load_contacts

  def index
    flash.keep
    redirect_to Group.root
  end

  def destroy
    super(location: entry.parent)
  end
  

  private 
  
  def build_entry 
    group = model_params.delete(:type).constantize.new
    group.parent_id = model_params.delete(:parent_id)
    group
  end

  def assign_attributes 
    role = entry.class.superior_attributes.present? && can?(:modify_superior, entry) ? :superior : :default
    entry.assign_attributes(model_params, as: role)
  end
  
  def load_contact
    @contact = entry.contact
  end

  def load_contacts
    @contacts = entry.people.affiliate(false).only_public_data.order_by_name
  end

end
