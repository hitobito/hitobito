class PeopleController < CrudController

  self.nesting = Group
  self.nesting_optional = true

  decorates :group, :person, :people


  skip_authorize_resource only: :list

  # load group before authorization
  prepend_before_filter :parent
  
  def index
    @external = false
    action = {'deep' => :deep_search, 'layer' => :layer_search}[params[:kind]] || :index
    @people = list_entries(action)
    if action != :index
      @people = @people.where(roles: {type: params[:role_types]})
      @all_roles = true
    else
      @people = @people.external(false).order_by_role
    end
    @people = @people.order_by_name
    respond_with(@people)
  end
  
  # list external people
  def external
    @external = true
    @people = list_entries.external(true).order_by_role.order_by_company
    respond_with(@people)
  end
  
  # GET ajax, without @group
  def query
    @people = []
    if params.has_key?(:q) && params[:q].size >= 3
      @people = Person.where(search_condition(:first_name, :last_name, :company_name, :nickname)).
                       only_public_data.
                       order_by_name.
                       limit(10)
    end
    
    render json: decorate(@people).collect(&:as_typeahead)
  end
  
  def filter
    
  end

  private
  
  def list_entries(action = :index)
    accessibles(action).
          preload_public_accounts.
          preload_groups.
          uniq
  end
  
  def build_entry
    person = super
    
    role = params[:role][:type].constantize.new
    role.group_id = params[:role][:group_id]
    authorize! :create, role
    
    person.roles << role
    
    person
  end
  
  def accessibles(action = :index)
    ability = Ability::Accessibles.new(current_user, @group)
    Person.accessible_by(ability, action)
  end
  
end