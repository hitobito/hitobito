# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationsController < CrudController

  include Concerns::RenderPeopleExports

  self.nesting = Group, Event

  self.permitted_attrs = [:additional_information,
                          answers_attributes: [:id, :question_id, :answer, answer: []],
                          application_attributes: [:id, :priority_2_id, :priority_3_id]]

  class_attribute :load_entries_includes
  self.load_entries_includes = [:roles, :event,
                                answers: [:question],
                                person: [:additional_emails, :phone_numbers,
                                         :primary_group]
                               ]

  self.remember_params += [:filter]

  self.search_columns = [:id, 'people.first_name', 'people.last_name', 'people.nickname']

  self.sort_mappings = { last_name:  'people.last_name',
                         first_name: 'people.first_name',
                         roles: lambda do |event|
                                  Person.order_by_name_statement.unshift(
                                    Event::Participation.order_by_role_statement(event)
                                  )
                                end,
                         nickname:   'people.nickname',
                         zip_code:   'people.zip_code',
                         town:       'people.town',
                         birthday:   'people.birthday' }


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

  after_create :send_confirmation_email
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
      created = with_callbacks(:create, :save) { save_entry }
      respond_with(entry, success: created, location: return_path)
    end
  end

  def index
    respond_to do |format|
      format.html do
        entries
        @person_add_requests = fetch_person_add_requests
      end
      format.pdf   { render_pdf(entries.collect(&:person), group) }
      format.csv   { render_tabular_in_background(:csv) && redirect_to(action: :index) }
      format.vcf   { render_vcf(entries.includes(person: :phone_numbers).collect(&:person)) }
      format.xlsx  { render_tabular_in_background(:xlsx) && redirect_to(action: :index) }
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

  def with_person_add_request(&block)
    creator = Person::AddRequest::Creator::Event.new(entry.roles.first, current_ability)
    msg = creator.handle(&block)
    redirect_to group_event_participations_path(group, event), alert: msg if msg
  end

  def list_entries
    records = event.active_participations_without_affiliate_types.
          includes(load_entries_includes).
          uniq
    # calling super here, so the searchable module on the listcontroller processes the query
    # this means that here also the affiliate type roles will be displayed, which is counter intuitive
    search_results = super.includes(load_entries_includes).references(:people) if params[:q]
    search_results_count = search_results ? search_results.count : 0
    filter = Event::ParticipationFilter.new(event, current_user, params, search_results_count)
    records = filter.list_entries(records).page(params[:page])
    @counts = filter.counts
    params[:q] ? search_results.page(params[:page]).per(50) : records.page(params[:page]).per(50)
  end

  def authorize_class
    authorize!(:index_participations, event)
  end

  def render_tabular_in_background(format)
    Export::EventParticipationsExportJob.new(format,
                                             current_person.id,
                                             event.id,
                                             event_participation_filter,
                                             params).enqueue!

    flash[:notice] = translate(:export_enqueued, email: current_person.email)
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

    if model_params && model_params.key?(:person_id)
      params[:for_someone_else] = true
      model_params.delete(:person)
      model_params.delete(:person_id)
    elsif params[:for_someone_else].blank?
      current_user.try(:id)
    end
  end

  def role_type
    role_type = params[:event_role] && params[:event_role][:type].presence
    role_type ||= event.class.participant_types.first.sti_name

    type = event.class.find_role_type!(role_type)
    unless type.participant?
      raise ActiveRecord::RecordNotFound, "No participant role '#{role_type}' found"
    end
    role_type
  end

  def set_active
    entry.active = !entry.applying_participant? || params[:for_someone_else].present?
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
    translate(:full_entry_label, model_label: models_label(false),
                                 person: h(entry.person),
                                 event: h(entry.event)).html_safe
  end

  def send_confirmation_email
    if entry.person_id == current_user.id
      Event::ParticipationConfirmationJob.new(entry).enqueue!
    end
  end

  def send_cancel_email
    if entry.person_id == current_user.id
      Event::CancelApplicationJob.new(entry.event, entry.person).enqueue!
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
    Event::ParticipationFilter.new(event, current_user, params)
  end

end
