# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Events::CoursesController < ApplicationController
  include Events::CourseListing
  include Events::EventListing

  helper_method :kind_used?, :display_any_booking_info?

  def index
    authorize_courses
    set_filter_vars

    respond_to do |format|
      format.html { prepare_sidebar }
      format.csv { render_tabular(:csv, limited_courses_scope) }
      format.xlsx { render_tabular(:xlsx, limited_courses_scope) }
    end
  end

  private

  def prepare_sidebar
    @grouped_events = sorted(grouped(limited_courses_scope, course_grouping))
    @categories = Event::KindCategory.list
    @kinds_without_category = Event::Kind.where(kind_category_id: nil)
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

  def course_scope
    Events::FilteredList.new(
      current_person, params,
      kind_used: kind_used?
    ).to_scope
  end

  def course_grouping
    kind_used? ? ->(event) { event.kind.label } : DEFAULT_GROUPING
  end

  def kind_used?
    Event::Course.attr_used?(:kind_id)
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
