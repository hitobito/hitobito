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
      scope = @scope
      scope = scope.in_hierarchy(@user) unless complete_course_list_allowed?
      group_ids.any? ? scope.with_group_id(group_ids) : scope
    end

    def default_user_course_group
      course_group_from_primary_layer || course_group_from_hierarchy
    end

    private

    def complete_course_list_allowed?
      @options[:list_all_courses] == true
    end

    def group_ids
      @params.dig(:filter, :group_ids).to_a.reject(&:blank?)
    end

    def course_group_from_primary_layer
      Group.
        course_offerers.
        where(id: @user.primary_group.try(:layer_group_id)).
        first
    end

    def course_group_from_hierarchy
      Group.
        course_offerers.
        where(id: @user.groups_hierarchy_ids).
        where('groups.id <> ?', Group.root.id).
        select(:id).
        first
    end
  end
end
