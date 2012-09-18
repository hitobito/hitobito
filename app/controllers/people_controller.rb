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
    render json: @people.collect {|p| {id: p.id, name: p.to_s} }
  end
  
  private
  
  def list_entries
    Person.accessible_by(current_ability).order_by_role.preload_public_accounts.preload_groups
  end
end