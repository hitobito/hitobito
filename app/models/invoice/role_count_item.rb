# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::RoleCountItem < InvoiceItem
  self.dynamic = true

  self.dynamic_cost_parameter_definitions = {
    role_types: :array,
    unit_cost: :decimal,
  }

  validates :role_types, :group_id, :period_start_on, presence: true
  validates :unit_cost, money: true

  def count
    @count ||= Role.joins(:group)
      .active(period_start_on..period_end_on)
      .where(group_id: group_scope)
      .where(person_id: person_scope)
      .where(type: role_types)
      # Don't distinguish roles with different type. Users can add a separate invoice item
      # if they want to distinguish those.
      .select("DISTINCT(person_id, group_id)")
      .count
  end

  def dynamic_cost = unit_cost * count

  private

  def group_scope
    # If the recipient is a person, we count roles in all groups of that person.
    return recipient.groups.select(:id) if recipient.is_a? Person
    # If the recipient is a group, we count roles in all descendants of this group.
    # If the recipient is nil, we count roles in all descendants of the invoice's sender group.
    Group.find(recipient&.id || group_id).self_and_descendants.select(:id)
  end

  def person_scope
    # If the recipient is a person, we count all matching roles of that person.
    return recipient.id if recipient.is_a? Person
    # Otherwise, we aggregate all roles regardless of the person they belong to.
    Person.all.select(:id)
  end

  def recipient
    invoice&.recipient
  end

  def role_types
    dynamic_cost_parameters[:role_types]
  end

  def unit_cost
    dynamic_cost_parameters[:unit_cost]
  end

  def group_id
    dynamic_cost_parameters[:group_id] || invoice&.group_id
  end

  def period_start_on
    dynamic_cost_parameters[:period_start_on]
  end

  def period_end_on
    dynamic_cost_parameters[:period_end_on]
  end
end
