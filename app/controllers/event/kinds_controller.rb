class Event::KindsController < CrudController


  before_render_form :load_assocations
  
  def create
    super(location: event_kinds_path)
  end
  
  def update
    super(location: event_kinds_path)
  end
    
  private
  
  def list_entries
    super.order(:deleted_at, :label)
  end
  
  def assign_attributes
    super
    entry.deleted_at = nil
  end
  
  def model_scope
    super.with_deleted
  end

  def load_assocations
    @preconditions = qualification_kinds | entry.preconditions
    @prolongations = qualification_kinds | entry.prolongations
    @qualification_kinds = qualification_kinds | entry.qualification_kinds
  end

  def qualification_kinds
    @qualification_kinds ||= QualificationKind.without_deleted
  end
  
  class << self
    def model_class
      Event::Kind
    end
  end
  
end
