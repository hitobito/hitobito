class PeopleController < CrudController

  self.nesting = Group
  self.nesting_optional = true

  decorates :group, :person, :people

  # load group before authorization
  prepend_before_filter :parent
  
  def index
    action = {'deep' => :deep_search, 'layer' => :layer_search}[params[:kind]] || :index
    
    @people = list_entries(action)
    
    if params[:role_types]
      @people = @people.where(roles: {type: params[:role_types]})
    else
      @people = @people.affiliate(false)
    end 
    
    if action != :index
      @multiple_groups = true
    else
      @people = @people.order_by_role
    end
    
    @people = @people.order_by_name
    respond_with(@people)
  end

  def history
    @roles = entry.all_roles
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
  
  def show
    if parent.nil?
      flash.keep
      redirect_to group_person_path(entry.groups.select('groups.id').first, entry)
    else
      super
    end
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
