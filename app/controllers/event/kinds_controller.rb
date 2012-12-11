class Event::KindsController < SimpleCrudController

  before_render_form :load_assocations
  

  private
  
  def list_entries
    super.order(:deleted_at, :label)
  end

  def load_assocations
    # append currently assigned values if they should not appear in the 
    # possible qualification kinds. May happen if they are marked as deleted.
    @preconditions = possible_qualification_kinds | entry.preconditions
    @prolongations = possible_qualification_kinds | entry.prolongations
    @qualification_kinds = possible_qualification_kinds | entry.qualification_kinds
  end

  def possible_qualification_kinds
    @possible_qualification_kinds ||= QualificationKind.without_deleted
  end
  
  class << self
    def model_class
      Event::Kind
    end
  end
  
end
