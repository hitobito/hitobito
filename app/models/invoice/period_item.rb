# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Abstract base class for dynamic invoice items which calculate their cost
# by counting some models within an invoice period and multiplying this count
# with a unit cost.
# Such items can be used in three separate contexts, and are expected to calculate
# the price for each of these contexts:
# 1. When not attached to an invoice: The item calculates a broad count of the relevant
#    models within some parent group. This is used for previewing the total amount on
#    an invoice form.
# 2. When attached to an invoice with a group as recipient: The item calculates the count
#    of models related to that specific recipient group. This is e.g. used for aggregated
#    membership fees which the recipient group has to pay to the root group.
# 3. When attached to an invoice with a persion as recipient: The item calculates the
#    count of models related to that specific person. This is e.g. used when sending
#    individual membership invoices to the individual members of a group.
#
# In all cases, a period item takes a period start date and an optional period end date,
# and only counts models which were "alive" or "active" some time in that period.
class Invoice::PeriodItem < InvoiceItem
  self.dynamic = true

  self.dynamic_cost_parameter_definitions = {
    unit_cost: :decimal
  }

  validates :period_start_on, presence: true
  validates :unit_cost, money: true

  def count
    # This is only a sample implementation. Subclasses may as well
    # redefine this method entirely.
    @count ||= base_scope # Count models...
      .active(period_start_on..period_end_on) # ... which were active in the period...
      .where(group_id: group_scope) # ... and which belong to relevant groups
      .count
  end

  def dynamic_cost = unit_cost * count

  private

  def base_scope
    raise "implement in subclass"
  end

  def group_scope
    within_group.self_and_descendants.select(:id)
  end

  def within_group
    # If the recipient is a group, we limit the model search to that group's descendants.
    return recipient if recipient&.is_a?(Group)
    # Otherwise, we consider models in any descendant of the invoice's sender group.
    Group.find(group_id)
  end

  def recipient
    invoice&.recipient
  end

  def unit_cost
    BigDecimal(dynamic_cost_parameters[:unit_cost])
  rescue ArgumentError, TypeError
    errors.add(:unit_cost, :is_not_a_decimal_number)
    BigDecimal(0)
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
