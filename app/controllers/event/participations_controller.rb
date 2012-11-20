class Event::ParticipationsController < CrudController
  
  self.nesting = Group, Event
  
  FILTER = { all: 'Alle Personen', 
             leaders: 'Leitungsteam', 
             participants: 'Teilnehmende' }
  
  decorates :event, :participation, :participations, :alternatives
  
  # load before authorization
  prepend_before_filter :entry, only: [:show, :new, :create, :edit, :update, :destroy, :print]
  prepend_before_filter :parent, :group

  before_filter :check_preconditions, only: [:create, :new]
  
  before_render_form :load_priorities
  before_render_show :load_answers

  after_create :create_participant_role
  after_create :send_confirmation_email
  
  def new
    assign_attributes
    entry.init_answers
    respond_with(entry)
  end
    
  def authorize!(action, *args)
    if [:index].include?(action)
      super(:index_participations, event)
    else
      super
    end
  end

  def print
    load_answers
    render :print, layout: false
  end

  def destroy
    super(location: group_event_application_market_index_path(group, event))
  end
  
  private

  def check_preconditions
    event = entry.event
    if entry.person == current_user && event.kind_of?(Event::Course)
      checker = Event::PreconditionChecker.new(event, current_user)
      redirect_to group_event_path(group, event), alert: checker.errors_text unless checker.valid?
    end
  end
    
  def list_entries(action = :index)
    records = event.participations.
                 where(event_participations: {active: true}).
                 includes(:person, :roles).
                 participating(event).
                 order_by_role(event.class).
                 merge(Person.order_by_name).
                 uniq
    Person::PreloadPublicAccounts.for(records.collect(&:person))

    # default event filters
    if scope = FILTER.keys.detect {|k| k.to_s == params[:filter] }
      # do not use params[:filter] in send to satisfy brakeman
      records = records.send(scope, event)

    # event specific filters (filter by role label)
    elsif label = event.participation_role_labels.any? {|k| k == params[:filter] }
      records = records.role_label(params[:filter])
    end
    
    records
  end
  
  # new and create are only invoked by people who wish to
  # apply for an event themselves. A participation for somebody
  # else is created through event roles. 
  # (Except for course participants, who may be created by special other roles)
  def build_entry
    participation = event.participations.new
    participation.person = current_user unless params[:for_someone_else]

    if event.supports_applications
      appl = participation.build_application
      appl.priority_1 = event
      if model_params && model_params.has_key?(:person_id)
        model_params.delete(:person)
        participation.person_id = model_params.delete(:person_id)
      end
    end

    participation
  end
  
  def event
    parent
  end
  
  def assign_attributes
    super
    # Set these attrs again as a new application instance might have been created by the mass assignment.
    entry.application.priority_1 ||= event if entry.application
  end
  
  def group
    @group ||= parents.first
  end
    
  def load_priorities
    if entry.application && entry.event.priorization
      @alternatives = Event::Course.application_possible.
                                    where(kind_id: event.kind_id).
                                    in_hierarchy(current_user).
                                    list
      @priority_2s = @priority_3s = (@alternatives.to_a - [event]) 
    end
  end
  
  def load_answers
    @answers = entry.answers.includes(:question)
    @application = Event::ApplicationDecorator.decorate(entry.application)
  end
  
  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    "#{models_label(false)} #{Event::ParticipationDecorator.decorate(entry).flash_info}".html_safe
  end

  def create_participant_role
    if !entry.event.supports_applications
      role = entry.event.participant_type.new
      role.participation = entry
      entry.roles << role
    end
  end
  
  def send_confirmation_email
    if entry.person_id == current_user.id
      Event::ParticipationConfirmationJob.new(entry).enqueue!
    end
  end

  class << self
    def model_class
      Event::Participation
    end
  end
end
