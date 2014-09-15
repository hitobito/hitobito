# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ListsController < ApplicationController
  include YearBasedPaging

  DEFAULT_GROUPING = ->(event) { I18n.l(event.dates.first.start_at, format: :month_year) }

  attr_reader :group_id
  helper_method :group_id

  skip_authorize_resource only: [:events, :courses]


  def events
    authorize!(:index, Event)

    @events_by_month = grouped(upcoming_user_events)
  end

  def courses
    authorize!(:index, Event::Course)
    set_group_vars

    grouped_courses = grouped(limited_courses_scope, course_grouping)
    @grouped_courses = sorted(grouped_courses)

    respond_to do |format|
      format.html { @grouped_courses }
      format.csv  { render_courses_csv(@grouped_courses.values.flatten) if can?(:export, Event) }
    end
  end

  private

  def grouped(scope, grouping = DEFAULT_GROUPING)
    EventDecorator.
      decorate_collection(scope).
      group_by { |event| grouping.call(event) }
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
    if can?(:manage_courses, Event)
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
    if can?(:manage_courses, Event)
      group_id > 0 ? course_scope.with_group_id(group_id) : course_scope
    else
      course_scope.in_hierarchy(current_user)
    end
  end

  def course_scope
    Event::Course
      .includes(:groups,  kind: :translations)
      .order('event_kind_translations.label')
      .in_year(year)
      .list
  end

  def course_grouping
    if Event::Course.used_attributes.include?(:kind_id)
      -> (event) { event.kind.label }
    else
      DEFAULT_GROUPING
    end
  end

end
