class Event::ApplicationsController < CrudController
  
  
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
    appl.participation.person = current_user
    appl
  end
  
end