class GroupsController < CrudController
  
  skip_authorize_resource only: [:index, :new, :show, :create]
  skip_authorization_check only: [:index, :show, :create]
  
  self.ability_types = {with_group: :all}
  
  include DisplayCase::ExhibitsHelper
  include ActionView::Helpers::FormOptionsHelper
 


  def index
    flash.keep
  end

  def show
    @current_ability = Ability::WithGroup.new(current_user, entry)
    super
  end

  def create(&block)
    assign_attributes
    created = with_callbacks(:create, :save) { entry.save }
    respond_with(entry, :success => created, &block)
  end
  
  def new
    # set parent group for authorization
    #entry
    #entry.parent_id = params.delete(:parent_id) if params.has_key?(:parent_id)
    @current_ability = Ability::WithGroup.new(current_user, entry.parent) if entry.parent
    authorize! :new, Group
    super
  end

  def fields
    assign_attributes
    render layout: nil, entry: entry
  end

  private 
  def build_entry 
    group = model_params[:type].constantize.new if model_params.has_key?(:type)
    group.parent_id = model_params[:parent_id] if model_params.has_key?(:parent_id)
    group
  end
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
