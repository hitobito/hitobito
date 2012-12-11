class Event::Camp::KindsController < SimpleCrudController

  private
  
  def list_entries
    super.order(:deleted_at, :label)
  end
  
  class << self
    def model_class
      Event::Camp::Kind
    end
  end
  
end
