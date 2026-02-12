# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::RoleCountItem < Invoice::PeriodItem
  validates :role_types, presence: true

  def role_types
    dynamic_cost_parameters[:role_types]
  end

  private

  def base_scope
    Role.joins(:group).joins(:person)
      .where(type: role_types)
      # Don't distinguish roles with different type. Users can add a separate invoice item
      # if they want to distinguish those.
      # However, if counting the roles for multiple recipients (ancestors) at the same time,
      # count occurrences for each ancestor separately.
      .select("DISTINCT(person_id, group_id, ancestor.id)")
  end
end
