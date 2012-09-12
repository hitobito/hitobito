class PeopleController < CrudController
  
  self.nesting = Group
  self.ability_types = {with_group: [:index, :external]}

  prepend_before_filter :parent
  
  def index
    @people = list_entries.external(false)
    respond_with(@people)
  end
  
  # list external people
  def external
    @people = list_entries.external(true)
    respond_with(@people)
  end
  
  private
  
  def list_entries
    Person.accessible_by(current_ability)
  end
end