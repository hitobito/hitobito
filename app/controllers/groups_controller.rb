class GroupsController < CrudController
  
  skip_authorize_resource only: [:index, :new]
  skip_authorization_check only: :index
  
  self.ability_types = {with_group: :all}
  
  include DisplayCase::ExhibitsHelper
  include ActionView::Helpers::FormOptionsHelper

  before_render_form :load_contacts


  def index
    flash.keep
    redirect_to Group.root
  end
  
  def new
    @current_ability = Ability::WithGroup.new(current_user, entry.parent) if entry.parent
    authorize! :new, Group
    super
  end

  private 
  def build_entry 
    group = model_params.delete(:type).constantize.new
    group.parent_id = model_params.delete(:parent_id)
    group
  end

  def set_model_ivar(value)
    super(exhibit(value))
  end

  def load_contacts
    @contacts = entry.people.external(false)
  end

end
