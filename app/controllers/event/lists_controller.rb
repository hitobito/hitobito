# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ListsController < ApplicationController
  include YearBasedPaging

  attr_reader :group_id
  helper_method :group_id

  skip_authorize_resource only: [:events, :courses]


  def events
    authorize!(:index, Event)

    @events_by_month = EventDecorator.decorate_collection(upcoming_user_events).
                                      group_by do |entry|
      l(entry.dates.first.start_at, format: :month_year)
    end
  end

  def courses
    authorize!(:index, Event::Course)
    set_group_vars
    load_courses_by_kind

    respond_to do |format|
      format.html { @courses_by_kind }
      format.csv  { render_courses_csv(@courses_by_kind.values.flatten) }
    end
  end

  private

  def render_courses_csv(courses)
    if can?(:export, Event)
      csv = Export::Csv::Events::List.export(courses)
      send_data csv, type: :csv
    end
  end

  def set_group_vars
    if can?(:manage_courses, Event)
      unless params[:year].present?
        params[:group_id] = default_user_course_group.try(:id)
      end
      @group_id = params[:group_id].to_i
    end
  end

  def load_courses_by_kind
    courses = EventDecorator.decorate_collection(limit_scope_for_user)
    @courses_by_kind = courses.group_by { |entry| entry.kind.label }
    @courses_by_kind.values.each do |entries|
      entries.sort_by! { |e| e.dates.first.try(:start_at) || Time.zone.now }.
              collect! { |e| EventDecorator.new(e) }
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

  def limit_scope_for_user
    if can?(:manage_courses, Event)
      group_id > 0 ? scope.with_group_id(group_id) : scope
    else
      scope.in_hierarchy(current_user)
    end
  end

  def scope
    Event::Course
      .includes(:groups,  kind: :translations)
      .order('event_kind_translations.label')
      .in_year(year)
      .list
  end

end
