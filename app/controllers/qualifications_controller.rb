class QualificationsController < CrudController

  skip_authorize_resource only: :create
  self.nesting = Group, Person


  def create
    authorize!(:create, entry)
    super(location: group_people_path(parents.first, parents.last))
  end
  
  def destroy
    authorize!(:destroy, entry)
    super(location: group_people_path(parents.first, parents.last))
  end


  private
  def build_entry
    parents.last.qualifications.build
  end

  
end
