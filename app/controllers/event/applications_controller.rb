class Event::ApplicationsController < CrudController
  self.nesting = Event
  
  private
  
  class << self
    def model_class
      Event::Application
    end
  end
  
  def build_entry
    course = Event::Course.find(params[:event_id])
    appl = Event::Application.new
    appl.priority_1 = course
    appl
  end
  
  def assign_attributes
    super
    entry.participation.person ||= current_user
    entry.participation.type ||= entry.priority_1.participant_type.sti_name
  end
  
  # No parent scope required here
  def parent_scope
    model_scope_without_nesting
  end
end