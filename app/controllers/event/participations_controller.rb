class Event::ParticipationsController < CrudController
  self.nesting = Event
  
  decorates :event, :people, :person
  
  # load event before authorization
  prepend_before_filter :parent, :set_group
  before_render_form :load_priorities
  
  
  def new
    assign_attributes
    entry.init_answers
    respond_with(entry)
  end
  
=begin
  def create
    super(location: event_participations_path(entry.event_id))
  end
  
  def update
    super(location: event_participation_path(entry.event_id, entry.id))
  end
  
  def destroy
    super(location: event_participations_path(entry.event_id))
  end
=end
    
    
  def authorize!(action, *args)
    if [:index, :show].include?(action)
      super(:index_participations, parent)
    else
      super
    end
  end
  
  private
    
  def list_entries(action = :index)
    parent.people.
           where(event_participations: {active: true}).
           preload_public_accounts.
           includes(:event_participations, :event_roles).
           order_by_participation(parent.class).
           order_by_name
  end
  
  def build_entry
    # delete unused attributes
    person_id = nil
    if model_params
      model_params.delete(:person)
      person_id = model_params.delete(:person_id)
    end

    participation = parent.participations.new
    participation.person_id = person_id || current_user.id
    if person_id.nil? && parent.supports_applications
      appl = participation.build_application
      appl.priority_1 = parent
    end
    participation
  end
  
  def assign_attributes
    super
    # Set these attrs again as a new application instance might have been created by the mass assignment.
    entry.application.priority_1 ||= parent if entry.application
  end
  
  def set_group
    @group = parent.group
  end
    
  def load_priorities
    if entry.application
      # TODO: restrict to visible courses
      @priority_2s = @priority_3s = Event::Course.where(kind_id: parent.kind_id)
    end
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