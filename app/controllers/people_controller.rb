class PeopleController < CrudController
  
  self.nesting = Group
  
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
    #@current_ability = Ability::WithGroup(current_user, @group)
    #Person.accessible_by(@current_ability)
    super
  end
end