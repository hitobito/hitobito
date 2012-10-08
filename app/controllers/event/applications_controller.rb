class Event::ApplicationsController < CrudController
  self.nesting = Event
  
  before_render_form :load_priorities
  
  
  class << self
    def model_class
      Event::Application
    end
  end
  
  
  private
  
  def load_priorities
    event = entry.priority_1
    # TODO: restrict to visible courses
    @priority_2s = @priority_3s = Event::Course.where(kind_id: event.kind_id)
  end
  
  def build_entry
    course = Event::Course.find(params[:event_id])
    course.build_application_for(current_user)
  end
  
  def assign_attributes
    super
    # Set these attrs again as a new participation instance might have been created by the mass assignment.
    entry.participation.person ||= current_user
    entry.participation.type ||= entry.priority_1.participant_type.sti_name
  end
  
  # No parent scope required here
  def parent_scope
    model_scope_without_nesting
  end
end