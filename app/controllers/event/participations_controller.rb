class Event::ParticipationsController < CrudController
  self.nesting = Event
    # load group before authorization
  prepend_before_filter :parent
  
  decorates :event
  
  hide_action :index, :show
  
  def create
    super(location: event_people_path(entry.event_id))
  end
  
  def update
    super(location: event_person_path(entry.event_id, entry.person_id))
  end
  
  def destroy
    super(location: event_people_path(entry.event_id))
  end
  
  private
  
  def build_entry 
    # delete unused attributes
    model_params.delete(:event_id)
    model_params.delete(:person)
    
    participation = model_params.delete(:type).constantize.new
    participation.event_id = parent.id
    participation.person_id = model_params.delete(:person_id)
    participation
  end
  
  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    "#{models_label(false)} #{Event::ParticipationDecorator.decorate(entry).flash_info}".html_safe
  end
  
  class << self
    def model_class
      Event::Participation
    end
  end
end