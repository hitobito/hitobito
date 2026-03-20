# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class GroupDetailsReadables < GroupReadables
  private

  def accessible_groups
    return Group.all if user.root?

    super.where(accessible_conditions.to_a).distinct
  end

  def accessible_conditions
    OrCondition.new.tap do |condition|
      append_group_conditions(condition)
      in_above_layer_condition(condition)
    end
  end
end
