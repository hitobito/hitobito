# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::CourseListing
  extend ActiveSupport::Concern

  included do
    helper_method :course_list_title
  end

  private

  def init_filter_vars
    set_group_vars
    set_date_range
    set_course_state_vars
  end

  def course_filters
    args = params.merge(list_all_courses: can?(:list_all, Event::Course))
    @filter = Events::Filter::CourseList.new(current_person, args)
  end

  def course_list_title
    @course_list_title ||= begin
      selected_kind_category_id = @filter.chain.dig(:course_kind_category, :id)
      return I18n.t("event.lists.courses.no_category") if selected_kind_category_id == "0"

      Event::KindCategory.find_by(id: selected_kind_category_id)&.label
    end
  end

  def set_course_state_vars
    params[:filters] ||= {}
    params[:filters][:state] ||= {}
    params[:filters][:state][:states] ||= Event::Course.possible_states.without("canceled")
  end

  def set_date_range
    params[:filters] ||= {}
    params[:filters][:date_range] ||= {
      since: I18n.l(Time.zone.today.to_date),
      until: I18n.l(1.year.from_now.to_date)
    }
  end

  def set_group_vars
    params[:filters] ||= {}
    params[:filters][:groups] ||= {}
    params[:filters][:groups][:ids] ||= course_groups_from_hierarchy.map(&:id)
  end

  def course_groups_from_hierarchy
    ids = current_person.primary_group&.hierarchy&.select(:id) ||
      current_person.groups_hierarchy_ids
    Group.where(id: ids).course_offerers
  end
end
