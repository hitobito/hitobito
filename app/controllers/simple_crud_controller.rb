# A Crud controller without a show action.
# Handles paranoid models as well.
class SimpleCrudController < CrudController
  
  
  def create
    super(location: index_path)
  end
  
  def update
    super(location: index_path)
  end
  
  private

  def assign_attributes
    super
    entry.deleted_at = nil if model_class.paranoid?
  end
    
end