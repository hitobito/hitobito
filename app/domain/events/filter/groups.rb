# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class Groups
    def initialize(user, params, options, scope)
      @user = user
      @params = params
      @scope = scope
      @options = options
    end

    def to_scope
      conditions = complete_course_list_allowed? ?
                     Event.all :
                     Event.in_hierarchy(@user).or(Event.where(globally_visible: true))

      conditions = conditions.with_group_id(group_ids) if group_ids.any?

      @scope.merge(conditions).distinct
    end

    def default_user_course_groups
      course_groups_from_primary_layer || course_groups_from_hierarchy || Group.none
    end

    private

    def complete_course_list_allowed?
      @options[:list_all_courses] == true
    end

    def group_ids
      @params.dig(:filter, :group_ids).to_a.compact_blank
    end

    def course_groups_from_primary_layer
      Group
        .course_offerers
        .where(id: @user.primary_group.try(:layer_group_id))
        .first
        .try(:hierarchy)
        .try(:course_offerers)
    end

    def course_groups_from_hierarchy
      Group
        .course_offerers
        .where(id: @user.groups_hierarchy_ids)
        .where.not(groups: {id: Group.root.id})
        .first
        .try(:hierarchy)
        .try(:course_offerers)
    end
  end
end
