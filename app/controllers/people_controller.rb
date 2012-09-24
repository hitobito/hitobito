class PeopleController < CrudController
  
  self.nesting = Group
  self.nesting_optional = true

  decorates :group, :person, :people

  # load group before authorization
  prepend_before_filter :parent
  
  def index
    @external = false
    @people = list_entries.order_by_name
    respond_with(@people)
  end
  
  # list external people
  def external
    @external = true
    @people = list_entries.order_by_company
    respond_with(@people)
  end
  
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
  
  private
  
  def list_entries
    accessibles = Ability::Accessibles.new(current_user, @group)
    Person.accessible_by(accessibles).
           external(@external).
           order_by_role.
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
  
end