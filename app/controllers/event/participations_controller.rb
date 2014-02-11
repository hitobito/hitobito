# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationsController < CrudController

  include RenderPeopleExports

  self.nesting = Group, Event
  self.remember_params += [:filter]

  decorates :group, :event, :participation, :participations, :alternatives

  # load before authorization
  prepend_before_filter :entry, only: [:show, :new, :create, :edit, :update, :destroy, :print]
  prepend_before_filter :parent, :group

  before_filter :check_preconditions, only: [:create, :new]

  before_render_form :load_priorities
  before_render_show :load_answers
  before_render_show :load_qualifications

  after_create :create_participant_role
  after_create :send_confirmation_email


  def new
    assign_attributes
    entry.init_answers
    respond_with(entry)
  end

  def index
    @participations = entries
    respond_to do |format|
      format.html
      format.pdf  { render_pdf(@participations.collect(&:person)) }
      format.csv  { render_csv }
      format.email  { render_emails(@participations.collect(&:person)) }
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

  def authorize_class
    authorize!(:index_participations, event)
  end

  def render_csv
    csv = params[:details] && can?(:show_details, entries.first) ?
      Export::Csv::People::ParticipationsFull.export.(entries) :
      Export::Csv::People::ParticipationsAddress.export(entries)

    send_data csv, type: :csv
  end

  def check_preconditions
    event = entry.event
    if user_course_application?
      checker = Event::PreconditionChecker.new(event, current_user)
      redirect_to group_event_path(group, event), alert: checker.errors_text unless checker.valid?
    end
  end

  def list_entries
    records = event.participations.
                    where(event_participations: { active: true }).
                    includes(:person, :roles, :event).
                    participating(event).
                    order_by_role(event.class).
                    merge(Person.order_by_name).
                    uniq
    Person::PreloadPublicAccounts.for(records.collect(&:person))

    # default event filters
    valid_scopes = FilterNavigation::Event::Participations::PREDEFINED_FILTERS.keys
    if scope = valid_scopes.detect { |k| k.to_s == params[:filter] }
      # do not use params[:filter] in send to satisfy brakeman
      records = records.send(scope, event) unless scope.to_s == 'all'

    # event specific filters (filter by role label)
    elsif event.participation_role_labels.include?(params[:filter])
      records = records.with_role_label(params[:filter])
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
      if model_params && model_params.key?(:person_id)
        model_params.delete(:person)
        participation.person_id = model_params.delete(:person_id)
        params[:for_someone_else] = true
      end
    end

    participation
  end

  def assign_attributes
    super
    # Set these attrs again as a new application instance might have been created by the mass assignment.
    entry.application.priority_1 ||= event if entry.application
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

  def load_qualifications
    @qualifications = entry.person.qualifications.includes(:qualification_kind).order_by_date
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    "#{models_label(false)} von " <<
    "<i>#{h(entry.person)}</i> in " <<
    "<i>#{h(entry.event)}</i>".html_safe
  end

  def create_participant_role
    if !entry.event.supports_applications || (can?(:create, event) && params[:for_someone_else])
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

  def set_success_notice
    if action_name.to_s == 'create'
      notice = "#{full_entry_label} wurde erfolgreich erstellt. " +
               'Bitte überprüfe die Kontaktdaten und passe diese gegebenenfalls an.'
      if user_course_application?
        notice += '<br />Für die definitive Anmeldung musst du diese Seite über <i>Drucken</i> ausdrucken, ' +
                  'unterzeichnen und per Post an die entsprechende Adresse schicken.'
      end
      flash[:notice] ||= notice
    else
      super
    end
  end

  def user_course_application?
    entry.person == current_user && event.supports_applications
  end

  def event
    parent
  end

  def group
    @group ||= parents.first
  end

  class << self
    def model_class
      Event::Participation
    end
  end
end
