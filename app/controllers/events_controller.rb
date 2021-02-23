# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventsController < CrudController
  include YearBasedPaging
  include AsyncDownload
  include Api::JsonPaging

  self.nesting = Group

  # Respective event attrs are added in corresponding instance method.
  self.permitted_attrs = [:signature, :signature_confirmation, :signature_confirmation_text,
                          :display_booking_info, :participations_visible, {
                            group_ids: [],
                            dates_attributes: [
                              :id, :label, :location, :start_at, :start_at_date,
                              :start_at_hour, :start_at_min, :finish_at,
                              :finish_at_date, :finish_at_hour, :finish_at_min,
                              :_destroy
                            ],
                            application_questions_attributes: [
                              :id, :question, :choices, :multiple_choices, :_destroy, :required
                            ],
                            admin_questions_attributes: [
                              :id, :question, :choices, :multiple_choices, :_destroy
                            ]
                          }]


  self.remember_params += [:year]

  self.sort_mappings = { name: 'event_translations.name', state: 'events.state',
                         dates_full: 'event_dates.start_at',
                         group_ids: "#{Group.quoted_table_name}.name" }

  self.search_columns = [:name]

  decorates :event, :events, :group

  prepend_before_action :authenticate_person_from_onetime_token!
  # load group before authorization
  prepend_before_action :parent

  before_render_show :load_user_participation
  before_render_form :load_sister_groups
  before_render_form :load_kinds

  def index
    respond_to do |format|
      format.html { @events = entries_page(params[:page]) }
      format.csv  { render_tabular_in_background(:csv) }
      format.xlsx { render_tabular_in_background(:xlsx) }
      format.ics  { render_ical(entries) }
      format.json { render_entries_json(entries) }
    end
  end

  def typeahead
    respond_to do |format|
      format.json { render json: for_typeahead(entries.where(search_conditions)) }
    end
  end

  def show
    respond_to do |format|
      format.html { entry }
      format.ics  { render_ical([entry]) }
      format.json { render_entry_json }
    end
  end

  def new
    assign_attributes if model_params
    entry.dates.build if entry.dates.empty? # allow wagons to use derived dates
    entry.init_questions
    respond_with(entry)
  end

  private

  # list scope preload :groups, :kinds which we dont need
  def list_entries
    event_filter.list_entries
  end

  def model_scope
    super.includes([:translations])
  end

  def build_entry
    if params[:source_id]
      group.events.find(params[:source_id]).duplicate
    else
      type = model_params && model_params[:type].presence
      type ||= Event.sti_name
      event = Event.find_event_type!(type).new
      event.groups << parent
      event
    end
  end

  def permitted_params
    p = model_params.dup
    p.delete(:type)
    p.delete(:contact)
    p.permit(permitted_attrs)
  end

  def group
    parent
  end

  def index_path
    typed_group_events_path(group, @event.class, returning: true)
  end

  def load_sister_groups
    master = @event.groups.first
    @groups = master.self_and_sister_groups.reorder(:name)
    # union to include assigned deleted events
    @groups = (@groups | @event.groups) - [group]
  end

  def load_kinds
    if entry.kind_class
      @kinds = entry.kind_class.list.without_deleted
      @kinds += [entry.kind] if entry.kind&.deleted?
    end
  end

  def load_user_participation
    if current_user
      @user_participation = current_user.event_participations.where(event_id: entry.id).first
    end
  end

  def render_tabular_in_background(format, name = :events_export)
    with_async_download_cookie(format, name) do |filename|
      Export::EventsExportJob.new(format,
                                  current_person.id,
                                  group.id,
                                  event_filter.to_h,
                                  filename: filename).enqueue!
    end
  end

  def render_ical(entries)
    send_data ::Export::Ics::Events.new.generate(entries), type: :ics, disposition: :inline
  end

  def for_typeahead(entries)
    entries.map do |entry|
      role_types = entry.role_types.map { |type| { label: type.label, name: type.name } }
      { id: entry.id, label: entry.name, types: role_types }
    end
  end

  def render_entries_json(entries)
    paged_entries = entries.page(params[:page])
    render json: [paging_properties(paged_entries),
                  ListSerializer.new(paged_entries.decorate,
                                     group: group,
                                     page: params[:page],
                                     serializer: EventSerializer,
                                     controller: self)].inject(&:merge)
  end

  def render_entry_json
    render json: EventSerializer.new(entry.decorate, group: @group, controller: self)
  end

  def typed_group_events_path(group, event_type, options = {})
    path = "#{event_type.type_name}_group_events_path"
    send(path, group, options)
  end

  def permitted_attrs
    attrs = entry.class.used_attributes
    attrs + self.class.permitted_attrs
  end

  def authorize_class
    type = params[:type].presence || 'Event'
    action = export? ? 'export' : 'index'
    authorize!(:"#{action}_#{type.underscore.pluralize}", group)
  end

  def export?
    format = request.format
    format.xlsx? || format.csv?
  end

  def assign_attributes
    assign_contact_attrs
    super
  end

  def assign_contact_attrs
    contact_attrs = model_params.delete(:contact_attrs)
    return if contact_attrs.blank?

    reset_contact_attrs
    contact_attrs.each do |a, v|
      entry.required_contact_attrs << a if v.to_sym == :required
      entry.hidden_contact_attrs << a if v.to_sym == :hidden
    end
  end

  def reset_contact_attrs
    entry.required_contact_attrs = []
    entry.hidden_contact_attrs = []
  end

  def event_filter
    if request.format.json?
      Event::ApiFilter.new(group, params, year)
    else
      expression = sort_expression if sorting?
      Event::Filter.new(group, params[:type], params[:filter], year, expression)
    end
  end

  def entries_page(page_param)
    page_scope = entries.page(page_param)

    if page_scope.out_of_range?
      entries.page(page_scope.total_pages)
    else
      page_scope
    end
  end

end
