# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventsController < CrudController
  include YearBasedPaging

  self.nesting = Group

  # Respective event attrs are added in corresponding instance method.
  self.permitted_attrs = [group_ids: [],
                          dates_attributes: [:id, :label, :location, :start_at, :start_at_date,
                                             :start_at_hour, :start_at_min, :finish_at,
                                             :finish_at_date, :finish_at_hour, :finish_at_min,
                                             :_destroy],
                          questions_attributes: [:id, :question, :choices, :multiple_choices,
                                                 :_destroy]]

  self.remember_params += [:year]

  decorates :event, :events, :group

  prepend_before_action :authenticate_person_from_onetime_token!
  # load group before authorization
  prepend_before_action :parent

  before_render_form :load_sister_groups
  before_render_form :load_kinds

  def new
    assign_attributes if model_params
    entry.dates.build
    entry.init_questions
    respond_with(entry)
  end

  # list scope preload :groups, :kinds which we dont need
  def list_entries
    model_scope.
      where(type: params[:type]).
      order_by_date.
      preload_all_dates.
      uniq.
      in_year(year)
  end

  private

  def build_entry
    type = model_params && model_params[:type].presence
    type ||= 'Event'
    event = Event.find_event_type!(type).new
    event.groups << parent
    event
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

  def typed_group_events_path(group, event_type, options = {})
    path = "#{event_type.type_name}_group_events_path"
    send(path, group, options)
  end

  def permitted_attrs
    attrs = entry.class.used_attributes
    attrs + self.class.permitted_attrs
  end

end
