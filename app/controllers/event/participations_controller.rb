# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationsController < CrudController # rubocop:disable Metrics/ClassLength

  include RenderPeopleExports
  include AsyncDownload
  include Api::JsonPaging
  include ActionView::Helpers::SanitizeHelper
  prepend RenderTableDisplays

  self.nesting = Group, Event

  self.permitted_attrs = [:additional_information,
                          answers_attributes: [:id, :question_id, :answer, answer: []],
                          application_attributes: [:id, :priority_2_id, :priority_3_id]]

  self.remember_params += [:filter]

  self.sort_mappings = { last_name: 'people.last_name',
                         first_name: 'people.first_name',
                         roles: lambda do |event|
                                  Person.order_by_name_statement.unshift(
                                    Event::Participation.order_by_role_statement(event)
                                  )
                                end,
                         nickname: 'people.nickname',
                         zip_code: 'people.zip_code',
                         town: 'people.town',
                         birthday: 'people.birthday' }


  decorates :group, :event, :participation, :participations, :alternatives

  # load before authorization
  prepend_before_action :entry, only: [:show, :new, :create, :edit, :update, :destroy, :print]
  prepend_before_action :parent, :group

  before_action :check_preconditions, only: [:new]

  before_render_new :init_answers
  before_render_edit :load_answers
  before_render_form :load_priorities
  before_render_show :load_answers
  before_render_show :load_precondition_warnings

  after_destroy :send_cancel_email

  # new and create are only invoked by people who wish to
  # apply for an event themselves. A participation for somebody
  # else is created through event roles.
  # (Except for course participants, who may be created by special other roles)
  def create
    assign_attributes
    init_answers
    set_active
    with_person_add_request do
      created = with_callbacks(:create, :save) do
        entry.transaction do
          next unless save_entry

          # a confirmation email gets sent automatically when assigning a
          # place. in the other case, send one explicitely
          directly_assign_place? ? directly_assign_place : send_confirmation_email
          send_notification_email
        end
      end
      respond_with(entry, success: created, location: return_path)
    end
  end

  def index # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    respond_to do |format|
      format.html do
        entries
        @person_add_requests = fetch_person_add_requests
      end
      format.pdf           { render_pdf(filter_entries.collect(&:person), group) }
      format.csv           { render_tabular_in_background(:csv) }
      format.vcf           { render_vcf(filter_entries.includes(person: :phone_numbers)
                                                      .collect(&:person)) }
      format.xlsx          { render_tabular_in_background(:xlsx) }
      format.email         { render_emails(filter_entries.collect(&:person), ',') }
      format.email_outlook { render_emails(filter_entries.collect(&:person), ';') }
      format.json          { render_entries_json(filter_entries) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render_entry_json }
    end
  end

  def print
    load_answers
    pdf = Export::Pdf::Participation.render(entry)
    filename = Export::Pdf::Participation.filename(entry)

    send_data pdf, type: :pdf, disposition: 'inline', filename: filename
  end

  def destroy
    location = if entry.person_id == current_user.id
                 group_event_path(group, event)
               else
                 group_event_application_market_index_path(group, event)
               end
    super(location: location)
  end

  def self.model_class
    Event::Participation
  end

  private

  def render_entry_json
    render json: EventParticipationSerializer.new(
      entry,
      {
        group: parents.first,
        event: parents.last,
        controller: self
      }
    )
  end

  def render_entries_json(entries)
    paged_entries = entries.page(params[:page])
    render json: [paging_properties(paged_entries),
                  ListSerializer.new(paged_entries.decorate,
                                     group: group,
                                     event: event,
                                     page: params[:page],
                                     serializer: EventParticipationSerializer,
                                     controller: self)].inject(&:merge)
  end

  def sort_mappings_with_indifferent_access
    list = event_participation_filter.list_entries.page(params[:page])
    super.merge(current_person.table_display_for(Event::Participation).sort_statements(list))
  end

  def with_person_add_request(&block)
    creator = Person::AddRequest::Creator::Event.new(entry.roles.first, current_ability)
    msg = creator.handle(&block)
    redirect_to group_event_participations_path(group, event), alert: msg if msg
  end

  def list_entries
    filter = event_participation_filter
    records = filter.list_entries.page(params[:page])
    @counts = filter.counts
    sort_param = params[:sort]

    records = records.reorder(Arel.sql(sort_expression)) if sort_param && sortable?(sort_param)
    Person::PreloadPublicAccounts.for(records.collect(&:person))
    records
  end

  def filter_entries
    event_participation_filter.list_entries
  end

  def authorize_class
    authorize!(:index_participations, event)
  end

  def render_tabular_in_background(format)
    with_async_download_cookie(format, :event_participation_export) do |filename|
      Export::EventParticipationsExportJob.new(format,
                                               current_person.id,
                                               event_participation_filter,
                                               params.merge(filename: filename)).enqueue!
    end
  end

  def check_preconditions
    load_precondition_warnings
    flash.now[:alert] = @precondition_warnings
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

  def build_entry
    participation = event.participations.new(person_id: person_id)
    role = participation.roles.build(type: role_type)
    role.participation = participation

    participation
  end

  def person_id
    return current_user.try(:id) unless event.supports_applications

    if model_params&.key?(:person_id)
      params[:for_someone_else] = true
      model_params.delete(:person)
      model_params.delete(:person_id)
    elsif params[:for_someone_else].blank?
      current_user.try(:id)
    end
  end

  def role_type
    role_type = params_role_type
    role_type ||= event.class.participant_types.first.sti_name

    type = event.class.find_role_type!(role_type)
    unless invited? || type.participant?
      raise ActiveRecord::RecordNotFound, "No participant role '#{role_type}' found"
    end

    role_type
  end

  def set_active
    entry.active = !entry.applying_participant? || params[:for_someone_else].present?
  end

  def invited?
    Event::Invitation.exists?(person: current_user,
                              event: event,
                              participation_type: params_role_type)
  end

  def params_role_type
    params[:event_role] && params[:event_role][:type].presence
  end

  def assign_attributes
    super

    # Required questions are enforced only for users that are not allowed to add others
    entry.enforce_required_answers = true unless can?(:update, entry)
  end

  def init_answers
    @answers = entry.init_answers
    entry.init_application
  end

  def directly_assign_place?
    event.places_available? && !(event.attr_used?(:priorization) && event.priorization)
  end

  def directly_assign_place
    assigner = Event::ParticipantAssigner.new(event, @participation)
    assigner.add_participant if assigner.createable?
  end

  def load_priorities
    if entry.application && event.priorization && current_user
      @alternatives = event.class.application_possible
                           .where(kind_id: event.kind_id)
                           .in_hierarchy(current_user)
                           .includes(:groups)
                           .list
      @priority_2s = @priority_3s = (@alternatives.to_a - [event])
    end
  end

  def load_answers
    @answers = entry.answers.includes(:question)
    if entry.application
      @application = Event::ApplicationDecorator.decorate(entry.application)
    end
  end

  def load_precondition_warnings
    if entry.person && entry.event.course_kind? && entry.roles.any? { |r| r.class.participant? }
      checker = Event::PreconditionChecker.new(entry.event, entry.person)
      @precondition_warnings = checker.errors_text unless checker.valid?
    end
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    label = translate(:full_entry_label, model_label: models_label(false),
                                         person: h(entry.person),
                                         event: h(entry.event))
    sanitize(label, tags: %w(i))
  end

  def send_confirmation_email
    if entry.person_id == current_user.id
      Event::ParticipationConfirmationJob.new(entry).enqueue!
    end
  end

  def send_notification_email
    if entry.person_id == current_user.id
      Event::ParticipationNotificationJob.new(entry).enqueue!
    end
  end

  def send_cancel_email
    if entry.person_id == current_user.id
      Event::CancelApplicationJob.new(entry.event, entry.person).enqueue!
    end
  end

  def set_success_notice
    return super unless action_name.to_s == 'create'

    if entry.pending?
      warn = translate(:pending, full_entry_label: full_entry_label)
      warn += '<br />' + translate(:instructions) if append_mailing_instructions?
      flash[:warn] ||= warn
      flash[:alert] ||= translate(:waiting_list) if entry.waiting_list?
    else
      notice = translate(:success, full_entry_label: full_entry_label)
      flash[:notice] ||= notice
    end
  end

  def append_mailing_instructions?
    entry.person == current_user && event.signature?
  end

  def event
    parent
  end

  def group
    @group ||= parents.first
  end

  # model_params may be empty
  def permitted_params
    model_params.present? ? model_params.permit(permitted_attrs) : {}
  end

  def fetch_person_add_requests
    p = event.participations.new
    role = p.roles.new(participation: p)
    if can?(:create, role)
      @event.person_add_requests.list.includes(person: :primary_group)
    end
  end

  def event_participation_filter
    user_id = current_user.try(:id)
    Event::ParticipationFilter.new(event.id, user_id, params)
  end

end
