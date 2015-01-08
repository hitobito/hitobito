# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationsController < CrudController

  include Concerns::RenderPeopleExports

  self.nesting = Group, Event

  self.permitted_attrs = [:additional_information,
                          answers_attributes: [:id, :question_id, :answer, answer: []],
                          application_attributes: [:id, :priority_2_id, :priority_3_id]]

  self.remember_params += [:filter]

  self.sort_mappings = { last_name:  'people.last_name',
                         first_name: 'people.first_name',
                         roles: lambda do |event|
                                  Person.order_by_name_statement.unshift(
                                  Event::Participation.order_by_role_statement(event))
                                end,
                         nickname:   'people.nickname',
                         zip_code:   'people.zip_code',
                         town:       'people.town' }


  decorates :group, :event, :participation, :participations, :alternatives

  # load before authorization
  prepend_before_action :entry, only: [:show, :new, :create, :edit, :update, :destroy, :print]
  prepend_before_action :parent, :group

  before_action :check_preconditions, only: [:create, :new]

  before_render_form :load_priorities
  before_render_show :load_answers
  before_render_show :load_qualifications

  after_create :send_confirmation_email

  # new and create are only invoked by people who wish to
  # apply for an event themselves. A participation for somebody
  # else is created through event roles.
  # (Except for course participants, who may be created by special other roles)
  def new
    assign_attributes if model_params
    entry.init_answers
    respond_with(entry)
  end

  def index
    respond_to do |format|
      format.html  { entries }
      format.pdf   { render_pdf(entries.collect(&:person)) }
      format.csv   { send_data(exporter.export(entries), type: :csv) }
      format.email { render_emails(entries.collect(&:person)) }
    end
  end

  def print
    load_answers
    pdf = Export::Pdf::Participation.render(entry)
    filename = Export::Pdf::Participation.filename(entry)

    send_data pdf, type: :pdf, disposition: 'inline', filename: filename
  end

  def destroy
    super(location: group_event_application_market_index_path(group, event))
  end

  private

  def list_entries
    filter = Event::ParticipationFilter.new(event, current_user, params)
    records = filter.list_entries
    @counts = filter.counts

    records = records.reorder(sort_expression) if params[:sort] && sortable?(params[:sort])
    Person::PreloadPublicAccounts.for(records.collect(&:person))
    records
  end

  def authorize_class
    authorize!(:index_participations, event)
  end

  def exporter
    if params[:details] && can?(:show_details, entries.first)
      Export::Csv::People::ParticipationsFull
    else
      Export::Csv::People::ParticipationsAddress
    end
  end

  def check_preconditions
    event = entry.event
    if user_course_application? && event.course_kind?
      checker = Event::PreconditionChecker.new(event, current_user)
      redirect_to group_event_path(group, event), alert: checker.errors_text unless checker.valid?
    end
  end

  def sort_columns
    params[:sort] == 'roles' ? sort_mappings_with_indifferent_access[:roles].call(event) : super
  end

  def find_entry
    if event.supports_applications
      # Every participation may be displayed underneath any event,
      # even if it does not directly belong to it.
      # This is to enable the display of entries on the waiting list.
      Event::Participation.find(params[:id])
    else
      super
    end
  end

  # new and create are only invoked by people who wish to
  # apply for an event themselves. A participation for somebody
  # else is created through event roles.
  # (Except for course participants, who may be created by special other roles)
  def build_entry
    participation = event.participations.new
    participation.person = current_user unless params[:for_someone_else]
    build_application(participation) if event.supports_applications
    build_participant_role(participation)
    participation
  end

  def build_application(participation)
    appl = participation.build_application
    appl.priority_1 = event
    if model_params && model_params.key?(:person_id)
      model_params.delete(:person)
      participation.person_id = model_params.delete(:person_id)
      params[:for_someone_else] = true
    end
  end

  def build_participant_role(participation)
    participation.active = !event.supports_applications ||
                           (can?(:create, event) && params[:for_someone_else].present?)

    role = participation.roles.build(type: find_participant_role)
    role.participation = participation
    role
  end

  def find_participant_role
    attrs = params[:event_role]
    type_name = (attrs && attrs[:type].presence) || event.class.participant_types.first.sti_name
    type = event.class.find_role_type!(type_name)
    unless type.participant?
      fail ActiveRecord::RecordNotFound, "No participant role '#{type_name}' found"
    end
    type_name
  end

  def assign_attributes
    super
    # Set these attrs again as a new application instance might have been
    # created by the mass assignment.
    entry.application.priority_1 ||= event if entry.application

    # Required questions are enforced only for users that are not allowed to add others
    entry.enforce_required_answers = true unless can?(:update, entry)
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
    @qualifications = entry.person.latest_qualifications_uniq_by_kind
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    translate(:full_entry_label, model_label: models_label(false),
                                 person: h(entry.person),
                                 event: h(entry.event)).html_safe
  end

  def send_confirmation_email
    if entry.person_id == current_user.id
      Event::ParticipationConfirmationJob.new(entry).enqueue!
    end
  end

  def set_success_notice
    if action_name.to_s == 'create'
      notice = translate(:success, full_entry_label: full_entry_label)
      notice += '<br />' + translate(:instructions) if append_mailing_instructions?
      flash[:notice] ||= notice
    else
      super
    end
  end

  def user_course_application?
    entry.person == current_user && event.supports_applications
  end

  def append_mailing_instructions?
    false
  end

  def event
    parent
  end

  def group
    @group ||= parents.first
  end

  # model_params may be empty
  def permitted_params
    model_params.permit(permitted_attrs)
  end

  def self.model_class
    Event::Participation
  end
end
