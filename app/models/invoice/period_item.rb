# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Abstract base class for dynamic invoice items which calculate their cost
# by counting some models within an invoice period and multiplying this count
# with a unit cost.
# Such items can be used in invoices addressed to groups or to people, or with a list
# or scope of groups or people, and are expected to calculate the price as follows:
# 1. When addressed to a single group: The item calculates the count of models related
#    to that specific recipient group. This is e.g. used for aggregated membership fees
#    which the recipient group has to pay to the root group.
# 2. When addressed to a single person: The item calculates the count of models related
#    to that specific recipient person. This is e.g. used when sending membership
#    invoices to the individual members of a group.
# 3. With a list of groups or a list of people: The item calculates the sum of counts
#    for each of these individual recipients. This is used for previewing the total
#    amount on an invoice form.
#
# In all cases, a period item takes a period start date and an optional period end date,
# and only counts models which were "alive" or "active" some time during that period.
class Invoice::PeriodItem < InvoiceItem
  self.dynamic = true

  def self.for_groups(groups, **params)
    new(**params).tap do |item|
      item.instance_variable_set(:@groups, groups)
    end
  end

  def self.for_people(people, **params)
    new(**params).tap do |item|
      item.instance_variable_set(:@people, people)
    end
  end

  validates :period_start_on, presence: true
  validates :unit_cost, money: true

  def count
    # This is only a sample implementation. Subclasses may as well
    # redefine this method entirely.
    @count ||= base_scope # Count models...
      .merge(group_condition) # ... which belong to relevant groups...
      .merge(people_condition) # ... which belong to relevant people...
      .active(period_start_on..period_end_on) # ... and which were active in the period
      .count
  end

  def dynamic_cost = unit_cost * count

  private

  def base_scope
    raise "implement in subclass"
  end

  def group_condition
    # Assumes the base_scope is already joined to the :group which the counted models belong to
    Group.joins(
      "INNER JOIN groups ancestor ON ancestor.lft <= groups.lft AND ancestor.rgt > groups.lft "
    ).where(ancestor: {id: groups})
  end

  def people_condition
    # Assumes the base_scope is already joined to the :person which the counted models belong to
    Person.where(id: people)
  end

  def groups
    # If no specific groups are given, fall back to the invoice recipient or invoice layer
    @groups ||= invoice&.recipient&.is_a?(Group) ? invoice.recipient_id : invoice&.group_id
  end

  def people
    # If no specific people are given, fall back to the invoice recipient or no people condition
    @people ||= invoice&.recipient&.is_a?(Person) ? invoice.recipient_id : Person.select(:id)
  end

  def unit_cost
    BigDecimal(dynamic_cost_parameters[:unit_cost])
  rescue ArgumentError, TypeError
    errors.add(:unit_cost, :is_not_a_decimal_number)
    BigDecimal(0)
  end

  def period_start_on
    dynamic_cost_parameters[:period_start_on]
  end

  def period_end_on
    dynamic_cost_parameters[:period_end_on]
  end
end
