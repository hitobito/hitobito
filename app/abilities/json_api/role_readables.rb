# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class RoleReadables < GroupBasedFetchables
    include FullReadablePeople

    # Groups whose people list is readable with a group based permission. As in the
    # people list of a group in the UI, the roles in these groups are readable,
    # even if the people themselves are not fully readable.
    self.same_group_permissions = [:group_full, :group_read,
      :group_and_below_full, :group_and_below_read]
    self.above_group_permissions = [:group_and_below_full, :group_and_below_read]

    def initialize(user)
      super

      can :read, Role, person: full_readable_people(user)
      can :read, Role, group: groups_with_readable_people if group_based_permissions?
    end

    private

    def groups_with_readable_people
      condition = OrCondition.new
      in_same_group_condition(condition)
      in_above_group_condition(condition)
      Group.where(condition.to_a)
    end

    def group_based_permissions?
      group_ids_same_group.present? || group_ids_above_group.present?
    end
  end
end
