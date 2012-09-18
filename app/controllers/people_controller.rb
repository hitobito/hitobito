class PeopleController < CrudController
  
  self.nesting = Group
  self.ability_types = {with_group: [:index, :external]}

  prepend_before_filter :parent
  
  def index
    @people = list_entries.external(false).order('people.last_name, people.first_name')
    respond_with(@people)
  end
  
  # list external people
  def external
    @people = list_entries.external(true).order('people.company_name, people.last_name')
    respond_with(@people)
  end
  
  private
  
  def list_entries
    Person.accessible_by(current_ability).order_by_role.preload_public_accounts.preload_groups
  end
end