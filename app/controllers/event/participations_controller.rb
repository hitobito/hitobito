class Event::ParticipationsController < CrudController
  self.nesting = Event
  
  decorates :event, :participation, :participations, :alternatives
  
  # load event before authorization
  prepend_before_filter :parent, :set_group
  before_render_form :load_priorities
  before_render_show :load_answers

  after_save :send_confirmation_email
  
  def new
    assign_attributes
    entry.init_answers
    respond_with(entry)
  end

    
  def authorize!(action, *args)
    if [:index].include?(action)
      super(:index_participations, parent)
    else
      super
    end
  end
  
  private
    
  def list_entries(action = :index)
    records = parent.participations.
                 where(event_participations: {active: true}).
                 includes(:person, :roles).
                 order_by_role(parent.class).
                 merge(Person.order_by_name)
    Person::PreloadPublicAccounts.for(records.collect(&:person))
    records
  end
  
  
  # new and create are only invoked by people who wish to
  # apply for an event themselves. A participation for somebody
  # else is created through event roles. 
  def build_entry
    participation = parent.participations.new
    participation.person = current_user
    if parent.supports_applications
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
    if entry.application && entry.event.priorization
      @alternatives = Event::Course.application_possible.
                                    where(kind_id: parent.kind_id).
                                    in_hierarchy(current_user).
                                    list
      @priority_2s = @priority_3s = (@alternatives.to_a - [parent]) 
    end
  end
  
  def load_answers
    @answers = entry.answers.includes(:question)
  end
  
  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    "#{models_label(false)} #{Event::ParticipationDecorator.decorate(entry).flash_info}".html_safe
  end

  def send_confirmation_email
    Event::ParticipationMailer.confirmation(current_user, @participation).deliver
  end
  
  class << self
    def model_class
      Event::Participation
    end
  end
end
