# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ListsController < ApplicationController
  include YearBasedPaging

  DEFAULT_GROUPING = ->(event) { I18n.l(event.dates.first.start_at, format: :month_year) }

  attr_reader :group_id
  helper_method :group_id, :kind_used?, :nav_left, :display_any_booking_info?

  skip_authorize_resource only: [:events, :courses]


  def events
    authorize!(:list_available, Event)

    @grouped_events = grouped(upcoming_user_events)
  end

  def courses
    authorize_courses
    set_group_vars

    respond_to do |format|
      format.html do
        @grouped_events = sorted(grouped(limited_courses_scope, course_grouping))
      end
      format.csv do
        render_tabular(:csv, limited_courses_scope)
      end
      format.xlsx do
        render_tabular(:xlsx, limited_courses_scope)
      end
    end
  end

  private

  def grouped(scope, grouping = DEFAULT_GROUPING)
    EventDecorator.
      decorate_collection(scope).
      group_by(&grouping)
  end

  def sorted(courses)
    courses.values.each do |entries|
      entries.sort_by! { |e| e.dates.first.try(:start_at) || Time.zone.now }
    end
    Hash[courses.sort]
  end

  def render_tabular(format, courses)
    send_data Export::Tabular::Events::List.export(format, courses), type: format
  end

  def set_group_vars
    if can?(:list_all, Event::Course)
      unless params[:year].present?
        params[:group_id] = default_user_course_group.try(:id)
      end
      @group_id = params[:group_id].to_i
    end
  end

  def upcoming_user_events
    Event.
      upcoming.
      in_hierarchy(current_user).
      includes(:dates, :groups).
      where('events.type != ? OR events.type IS NULL', Event::Course.sti_name).
      order('event_dates.start_at ASC')
  end

  def default_user_course_group
    course_group_from_primary_layer || course_group_from_hierarchy
  end

  def course_group_from_primary_layer
    Group.
      course_offerers.
      where(id: current_user.primary_group.try(:layer_group_id)).
      first
  end

  def course_group_from_hierarchy
    Group.
      course_offerers.
      where(id: current_user.groups_hierarchy_ids).
      where('groups.id <> ?', Group.root.id).
      select(:id).
      first
  end

  def limited_courses_scope(scope = course_scope)
    if can?(:list_all, Event::Course)
      group_id > 0 ? scope.with_group_id(group_id) : scope
    else
      scope.in_hierarchy(current_user)
    end
  end

  def course_scope
    Event::Course.
      includes(:groups, additional_course_includes).
      order(course_ordering).
      in_year(year).
      list
  end

  def course_grouping
    kind_used? ? ->(event) { event.kind.label } : DEFAULT_GROUPING
  end

  def course_ordering
    kind_used? ? 'event_kind_translations.label, event_dates.start_at' : 'event_dates.start_at'
  end

  def additional_course_includes
    kind_used? ? { kind: :translations } : {}
  end

  def kind_used?
    Event::Course.attr_used?(:kind_id)
  end

  def nav_left
    @nav_left || params[:action]
  end

  def display_any_booking_info?
    @grouped_events.values.flatten.any? { |e| e.display_booking_info? }
  end

  def authorize_courses
    if request.format.csv?
      authorize!(:export_list, Event::Course)
    else
      authorize!(:list_available, Event::Course)
    end
  end

end
