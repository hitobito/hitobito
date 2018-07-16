# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventsController < CrudController
  include YearBasedPaging
  include Concerns::AsyncDownload

  self.nesting = Group

  # Respective event attrs are added in corresponding instance method.
  self.permitted_attrs = [:signature, :signature_confirmation, :signature_confirmation_text,
                          :display_booking_info,
                          group_ids: [],
                          dates_attributes: [
                            :id, :label, :location, :start_at, :start_at_date,
                            :start_at_hour, :start_at_min, :finish_at,
                            :finish_at_date, :finish_at_hour, :finish_at_min,
                            :_destroy
                          ],
                          application_questions_attributes: [
                            :id, :question, :choices, :multiple_choices, :required, :_destroy
                          ],
                          admin_questions_attributes: [
                            :id, :question, :choices, :multiple_choices, :_destroy
                          ]]


  self.remember_params += [:year]

  self.sort_mappings = { name: 'events.name', state: 'events.state',
                         dates_full: 'event_dates.start_at',
                         group_ids: 'groups.name' }

  decorates :event, :events, :group

  prepend_before_action :authenticate_person_from_onetime_token!
  # load group before authorization
  prepend_before_action :parent

  before_render_show :load_user_participation
  before_render_form :load_sister_groups
  before_render_form :load_kinds

  def index
    respond_to do |format|
      format.html { @events = entries.page(params[:page]) }
      format.csv  { render_tabular_in_background(:csv) && redirect_to(action: :index) }
      format.xlsx { render_tabular_in_background(:xlsx) && redirect_to(action: :index) }
      format.ics { render_ical(entries) }
    end
  end

  def show
    respond_to do |format|
      format.html  { entry }
      format.ics { render_ical([entry]) }
    end
  end

  def new
    assign_attributes if model_params
    entry.dates.build
    entry.init_questions
    respond_with(entry)
  end

  private

  # list scope preload :groups, :kinds which we dont need
  def list_entries
    event_filter.list_entries
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
      @kinds << entry.kind if entry.kind && entry.kind.deleted?
    end
  end

  def load_user_participation
    if current_user
      @user_participation = current_user.event_participations.where(event_id: entry.id).first
    end
  end

  def render_tabular_in_background(format)
    with_async_download_cookie(format, :events_export) do |filename|
      Export::EventsExportJob.new(format,
                                  current_person.id,
                                  event_filter,
                                  filename: filename).enqueue!
    end
  end

  def render_ical(entries)
    send_data ::Export::Ics::Events.new.generate(entries), type: :ics, disposition: :inline
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
    expression = sort_expression if sorting?
    Event::Filter.new(params[:type], params['filter'], group, year, expression)
  end

end
