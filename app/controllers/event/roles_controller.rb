class Event::RolesController < CrudController
   
   
  self.nesting = Event
  
  decorates :event_role, :event
    
  # load group before authorization
  prepend_before_filter :parent
  
  hide_action :index, :show
  
  
  def create
    super(location: event_participations_path(parent.id))
  end
  
  def update
    super(location: event_participation_path(parent.id, entry.participation_id))
  end
  
  def destroy
    super(location: event_participations_path(parent.id))
  end
  
  private 
  
  def build_entry 
    # delete unused attributes
    model_params.delete(:event_id)
    model_params.delete(:person)
    
    role = model_params.delete(:type).constantize.new
    role.participation = parent.participations.where(:person_id => model_params.delete(:person_id)).first_or_initialize
    role
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    "#{models_label(false)} #{Event::RoleDecorator.decorate(entry).flash_info}".html_safe
  end
  
  class << self
    def model_class
      Event::Role
    end
  end
  
end