# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::RoleCountItem < Invoice::PeriodItem
  self.dynamic_cost_parameter_definitions = {
    role_types: :array,
    unit_cost: :decimal
  }

  validates :role_types, :group_id, :period_start_on, presence: true

  def count
    @count ||= base_scope
      .active(period_start_on..period_end_on)
      .where(group_id: group_scope)
      .where(person_id: person_scope)
      .where(type: role_types)
      # Don't distinguish roles with different type. Users can add a separate invoice item
      # if they want to distinguish those.
      .select("DISTINCT(person_id, group_id)")
      .count
  end

  private

  def base_scope
    Role.joins(:group)
  end

  def person_scope
    # If the recipient is a person, we count all matching roles of that person only.
    return recipient.id if recipient.is_a? Person
    # Otherwise, we aggregate all roles regardless of the person they belong to.
    Person.all.select(:id)
  end

  def role_types
    dynamic_cost_parameters[:role_types]
  end
end
