class GroupsController < CrudController
  
  skip_authorize_resource only: [:index, :new]
  skip_authorization_check only: :index
  
  self.ability_types = {with_group: :all}
  
  include DisplayCase::ExhibitsHelper
  include ActionView::Helpers::TagHelper


  def new
    if model_params && model_params.has_key?(:parent_id)
      super
    else
      redirect_to new_group_path(group: { parent_id: 1 })
    end
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

  def fields
    assign_attributes
    render layout: nil, entry: entry
  end

  private 
  def assign_attributes 
    if model_params && entry.new_record? 
      entry.type = model_params.delete(:type)
      entry.parent_id = model_params.delete(:parent_id) 
    end
    super
  end

  def set_model_ivar(value)
    super(exhibit(value))
  end

end
