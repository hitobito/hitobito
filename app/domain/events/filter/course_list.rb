# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Lists courses for the main left nav "Kurse" view
class Events::Filter::CourseList < Events::Filter::List
  def entries
    super.preload(additional_course_includes)
  end

  def event_type
    Event::Course
  end

  private

  def default_order(scope)
    scope
      .list
      .joins(additional_course_includes)
      .reorder(order_clause)
  end

  def order_clause
    kind_used? ? "event_kind_translations.label, start_at" : "start_at"
  end

  def base_scope
    if params[:list_all_courses] == true
      Event::Course.all
    else
      # Users can only show events in their own layer. Hence `in_hierarchy` will
      # list events that cannot be showed or applied to. This is weird legacy behaviour.
      # At some time, either events in the hierarchy should become showable or they
      # should not be listed here. Then, using the original `accessible_scope` method with
      # `Event.accessible_by(EventReadables)` would be sufficient.
      Event::Course.in_hierarchy(user).or(Event::Course.where(globally_visible: true))
    end
  end

  def accessible_scope
    Event::Course.all
  end

  def additional_course_includes
    kind_used? ? {kind: :translations} : {}
  end

  def kind_used?
    Event::Course.attr_used?(:kind_id)
  end
end
