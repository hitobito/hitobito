class QualificationsController < CrudController

  self.nesting = Group, Person
  
  # load parents before authorization
  prepend_before_filter :parent
  
  before_render_form :load_qualification_kinds

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
  
  def load_qualification_kinds
    @qualification_kinds = QualificationKind.without_deleted
  end
  
end
