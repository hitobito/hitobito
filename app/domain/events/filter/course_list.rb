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
      Event::Course.in_hierarchy(user).or(Event::Course.where(globally_visible: true))
    end
  end

  def additional_course_includes
    kind_used? ? {kind: :translations} : {}
  end

  def kind_used?
    Event::Course.attr_used?(:kind_id)
  end
end
