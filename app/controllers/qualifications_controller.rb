class QualificationsController < CrudController

  self.nesting = Group, Person
  
  # load parents before authorization
  prepend_before_filter :parent

  def create
    super(location: group_person_path(@group, @person))
  end
  
  def destroy
    super(location: group_person_path(@group, @person))
  end

  private
  
  def build_entry
    @person.qualifications.build
  end
  
end
