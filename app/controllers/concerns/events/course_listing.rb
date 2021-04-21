# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::CourseListing
  extend ActiveSupport::Concern

  included do
    attr_reader :group_id, :since_date, :until_date
    helper_method :group_id, :since_date, :until_date
  end

  private

  def set_filter_vars
    set_group_vars
    set_date_vars
    set_kind_category_vars
  end

  def set_group_vars
    if can?(:list_all, Event::Course)
      if params[:year].blank?
        params[:group_id] = default_user_course_group.try(:id)
      end
      @group_id = params[:group_id].to_i
    end
  end

  def set_date_vars
    @since_date = date_or_default(params.dig(:filter, :since), Time.zone.today.to_date)
    @until_date = date_or_default(params.dig(:filter, :until), @since_date.advance(years: 1))
    @since_date = I18n.l(@since_date)
    @until_date = I18n.l(@until_date)
  end

  def date_or_default(date, default)
    Date.parse(date)
  rescue
    default
  end

  def set_kind_category_vars
    @kind_category_id = params.dig(:category).to_i
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
      group_id.positive? ? scope.with_group_id(group_id) : scope
    else
      scope.in_hierarchy(current_user)
    end
  end

end
