# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ListsController < ApplicationController
  include YearBasedPaging

  DEFAULT_GROUPING = ->(event) { I18n.l(event.dates.first.start_at, format: :month_year) }

  attr_reader :group_id
  helper_method :group_id, :kind_used?

  skip_authorize_resource only: [:events, :courses]


  def events
    authorize!(:list_available, Event)

    @grouped_events = grouped(upcoming_user_events)
  end

  def courses
    if request.format.csv?
      authorize!(:export_list, Event::Course)
    else
      authorize!(:list_available, Event::Course)
    end

    set_group_vars
    respond_to do |format|
      format.html do
        grouped_courses = grouped(limited_courses_scope, course_grouping)
        @grouped_events = sorted(grouped_courses)
      end
      format.csv do
        render_courses_csv(limited_courses_scope)
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
    courses
  end

  def render_courses_csv(courses)
    send_data Export::Csv::Events::List.export(courses), type: :csv
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
    Event.upcoming.
          in_hierarchy(current_user).
          includes(:dates, :groups).
          where('events.type != ? OR events.type IS NULL', Event::Course.sti_name).
          order('event_dates.start_at ASC')
  end

  def default_user_course_group
    Group.course_offerers.
          where(id: current_user.groups_hierarchy_ids).
          where('groups.id <> ?', Group.root.id).
          select(:id).
          first
  end

  def limited_courses_scope
    if can?(:list_all, Event::Course)
      group_id > 0 ? course_scope.with_group_id(group_id) : course_scope
    else
      course_scope.in_hierarchy(current_user)
    end
  end

  def course_scope
    Event::Course
      .includes(:groups, additional_course_includes)
      .order(course_ordering)
      .in_year(year)
      .list
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

end
