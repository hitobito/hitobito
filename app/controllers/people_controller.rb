class PeopleController < CrudController
  
  self.nesting = Group
  self.nesting_optional = true
  self.ability_types = {with_group: [:index, :external]}

  # load group before authorization
  prepend_before_filter :parent
  
  def index
    @people = exhibit(list_entries.external(false).order_by_name)
    respond_with(@people)
  end
  
  # list external people
  def external
    @people = exhibit(list_entries.external(true).order_by_company)
    respond_with(@people)
  end
  
  def query
    @people = []
    if params.has_key?(:q) && params[:q].size >= 3
      @people = Person.where(search_condition(:first_name, :last_name, :company_name, :nickname)).only_public_data.order_by_name
    end
    
    render json: @people.collect{|p| exhibit(p).as_typeahead }
  end
  
  private
  
  def list_entries
    Person.accessible_by(current_ability).order_by_role.preload_public_accounts.preload_groups.uniq
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