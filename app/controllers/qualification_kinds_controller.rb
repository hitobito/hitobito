class QualificationKindsController < SimpleCrudController

  private
  
  def list_entries
    super.order(:deleted_at, :label)
  end
  
end