class GroupsController < CrudController
  
  skip_authorize_resource only: [:index, :new]
  skip_authorization_check only: :index
  
  self.ability_types = {with_group: :all}
  
  include DisplayCase::ExhibitsHelper

  def set_model_ivar(value)
    super(exhibit(value))
  end

  def index
    flash.keep
    redirect_to Group.root
  end
  
  def new
    # set parent group for authorization
    entry
    entry.parent_id = params[:group].delete(:parent_id) if params[:group]
    @current_ability = Ability::WithGroup.new(current_user, entry.parent) if entry.parent
    authorize! :new, Group
    super
  end
  
  
end
