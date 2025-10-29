# frozen_string_literal: true

#  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
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

  self.permitted_attrs = [:additional_information, :participant_id, :participant_type,
    answers_attributes: [:id, :question_id, :answer, answer: []],
    application_attributes: [:id, :priority_2_id, :priority_3_id]]

  self.remember_params += [:filter]

  class << self
    def polymorphic_sort_mapping(column)
      if [Person, Event::Guest].all? { |c| c.column_names.include?(column) }
        order_alias = "#{column}_order_statement"
        order_statement = "CASE event_participations.participant_type WHEN 'Person' " \
          "THEN people.#{column} " \
          "WHEN 'Event::Guest' THEN event_guests.#{column} END AS #{order_alias}"
        {order: order_statement, order_alias: order_alias}
      else
        {order: "people.#{column}"}
      end
    end
  end

  self.sort_mappings = {
    last_name: polymorphic_sort_mapping(:last_name),
    first_name: polymorphic_sort_mapping(:first_name),
    nickname: polymorphic_sort_mapping(:nickname),
    zip_code: polymorphic_sort_mapping(:zip_code),
    town: polymorphic_sort_mapping(:town),
    birthday: polymorphic_sort_mapping(:birthday),
    # for sorting roles we dont want to explicitly add a join_table statement when default_sort is
    # configured to role. In case of default_sort being role, order_by_role is already called in
    # the participation_filter (so the joined table is in the query already)
    roles: {
      joins: [:roles].tap do |joins|
        # rubocop:todo Layout/LineLength
        joins << "INNER JOIN event_role_type_orders ON event_roles.type = event_role_type_orders.name" unless Settings.people.default_sort == "role"
        # rubocop:enable Layout/LineLength
      end,
      order: [].tap do |order|
        # rubocop:todo Layout/LineLength
        order << "event_role_type_orders.order_weight" unless Settings.people.default_sort == "role"
        # rubocop:enable Layout/LineLength
        order.concat(["people.last_name", "people.first_name"])
      end
    }
  }

  decorates :group, :event, :participation, :alternatives

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
          next false unless save_entry

          # a confirmation email gets sent automatically when assigning a
          # place. in the other case, send one explicitely
          directly_assign_place? ? directly_assign_place : send_confirmation_email
          send_notification_email
        end
      end

      respond_with(entry, success: created, location: after_create_location(entry))
    end
  end

  def index # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    respond_to do |format|
      format.html do
        @participations = decorated_entries
        @person_add_requests = fetch_person_add_requests
      end
      format.pdf { render_entries_pdf(filter_entries) }
      format.csv { render_tabular_in_background(:csv) }
      format.vcf { render_vcf(filter_entries.includes(person: :phone_numbers).collect(&:person)) }
      format.xlsx { render_tabular_in_background(:xlsx) }
      format.email { render_emails(filter_entries.collect(&:person), ",") }
      format.email_outlook { render_emails(filter_entries.collect(&:person), ";") }
      format.json { render_entries_json(filter_entries) }
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

    send_data pdf, type: :pdf, disposition: "inline", filename: filename
  end

  def destroy
    super(location: after_destroy_path)
  end

  def self.model_class
    Event::Participation
  end

  private

  def decorated_entries
    PaginatingDecorator.new(
      entries,
      with: Event::ParticipationDecorator,
      context: {blocked_emails: load_blocked_emails(entries.flat_map(&:person))}
    )
  end

  def load_blocked_emails(people)
    emails = people.flat_map do |person|
      [person.email, *person.additional_emails.map(&:value)]
    end.uniq.compact
    Bounce.blocked_set(emails)
  end

  def render_entries_pdf(entries)
    render_pdf(entries.collect(&:person), group, event.to_s)
  end

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

  def after_destroy_path
    if for_current_user?
      group_event_path(group, event)
    else
      group_event_application_market_index_path(group, event)
    end
  end

  def with_person_add_request(&)
    creator = Person::AddRequest::Creator::Event.new(entry.roles.first, current_ability)
    msg = creator.handle(&)
    redirect_to return_path || group_event_participations_path(group, event), alert: msg if msg
  end

  def list_entries
    records = sort_by_sort_expression(entries_scope)
      .merge(Person.preload_picture)
      .page(params[:page])

    Person::PreloadPublicAccounts.for(records.select { |participation|
      participation.participant_type == Person.sti_name
    }.collect(&:person))
    @pagination_options = {
      total_pages: records.total_pages,
      current_page: records.current_page,
      per_page: records.limit_value
    }
    records
  end

  # Extracted as a separate method, so wagons can add to the scope before sorting and especially
  # the PreloadPublicAccounts step, which requires to load the page of records into memory
  def entries_scope
    filter = event_participation_filter
    records = filter.list_entries
      .select(Event::Participation.column_names)
    @counts = filter.counts
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
        event.id,
        group.id,
        params.merge(filename: filename)).enqueue!
    end
  end

  def check_preconditions
    load_precondition_warnings
    flash.now[:alert] = @precondition_warnings
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
    participation = event.participations.new(participant_id: person_id,
      participant_type: Person.sti_name)
    role = participation.roles.build(type: role_type)
    role.participation = participation

    participation
  end

  def person_id # rubocop:todo Metrics/CyclomaticComplexity
    return current_user&.id unless event.supports_applications

    if model_params&.key?(:person_id)
      params[:for_someone_else] = true
      model_params.delete(:person)
      model_params.delete(:person_id)
    elsif params[:for_someone_else].blank?
      current_user&.id
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
    Event::Invitation.exists?(
      person: current_user,
      event: event,
      participation_type: params_role_type
    )
  end

  def params_role_type
    params[:event_role] && params[:event_role][:type].presence
  end

  def assign_attributes
    super

    entry.enforce_required_answers = enforce_required_answers?
  end

  def init_answers
    @answers = entry.init_answers
    entry.init_application
  end

  def directly_assign_place?
    event.places_available? &&
      (event.attr_used?(:automatic_assignment) && event.automatic_assignment?)
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
    @answers = entry.answers.list
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
    sanitize(label, tags: %w[i])
  end

  def send_confirmation_email
    # rubocop:todo Layout/LineLength
    # send_email? is used when adding someone_else and checking the checkmark to send the confirmation mail
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    # while current_user_interested_in_mail? makes sure to send the confirmation if you're registering yourself for the event.
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    Event::ParticipationConfirmationJob.new(entry).enqueue! if send_email? || current_user_interested_in_mail?
    # rubocop:enable Layout/LineLength
  end

  def send_notification_email
    Event::ParticipationNotificationJob.new(entry).enqueue! if current_user_interested_in_mail?
  end

  def send_cancel_email
    if current_user_interested_in_mail?
      Event::CancelApplicationJob.new(entry.event, entry.person).enqueue!
    end
  end

  def current_user_interested_in_mail?
    for_current_user? # extended in wagon
  end

  def enforce_required_answers?
    for_current_user? # extended in wagon
  end

  # rubocop:todo Metrics/AbcSize
  def set_success_notice # rubocop:todo Metrics/CyclomaticComplexity # rubocop:todo Metrics/AbcSize
    return super unless action_name.to_s == "create"

    if entry.pending?
      warn = translate(:pending, full_entry_label: full_entry_label)
      warn += "<br />" + translate(:instructions) if append_mailing_instructions?
      flash[:warning] ||= warn
      flash[:alert] ||= translate(:waiting_list) if entry.waiting_list?
    else
      notice = translate(:success, full_entry_label: full_entry_label)
      flash[:notice] ||= notice
    end
  end
  # rubocop:enable Metrics/AbcSize

  def after_create_location(participation)
    if participation.persisted? && params.key?(:add_another)
      return new_group_event_guest_path(
        params[:group_id],
        params[:event_id],
        participation.id
      )
    end

    return_path
  end

  def append_mailing_instructions?
    for_current_user? && event.signature?
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
      @event.person_add_requests
        .select("person_add_requests.*")
        .list
        .includes(person: :primary_group)
    end
  end

  def event_participation_filter
    @participation_filter ||= Event::ParticipationFilter.new(event, current_user, params)
  end

  def send_email?
    true?(params[:send_email])
  end

  def for_current_user?
    entry.participant_type == Person.sti_name && entry.participant_id == current_user&.id
  end
end
