# frozen_string_literal: true

#  Copyright (c) 2012-2026, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# STI base class for invoice item templates used in a period invoice template.
# This class is not intended to be instantiated or persisted directly, only
# subclasses of it.
# All methods in this class are intended to be overridden in subclasses.
#
# The invoice item templates are mostly wrappers for configuration which
# will be passed to actual concrete invoice items when generating an invoice
# run containing actual invoices.
# As such, they have mostly the same columns as invoice items.
# In order to actually calculate counts and prices, the
# #to_invoice_item_for_groups r #to_invoice_item_for_people method
# is used to get an invoice item that can perform the calculation.
class PeriodInvoiceTemplate::Item < ActiveRecord::Base
  include Globalized

  self.table_name = "period_invoice_template_items"

  translates :name

  serialize :dynamic_cost_parameters, type: Hash, coder: YAML
  belongs_to :period_invoice_template

  # This base class may not be instantiated
  validates :type, exclusion: {in: %w[PeriodInvoiceTemplate::Item]}
  validates :name, :unit_cost, presence: true
  validates :unit_cost, money: true, unless: proc { |i| i.unit_cost.nil? }

  before_validation :enforce_unit_cost_precision

  def dynamic_cost_parameter_definitions
    invoice_item_class.dynamic_cost_parameter_definitions
  end

  def to_invoice_item_for_groups(invoice: nil, recipient_groups: period_invoice_template.group_id)
    invoice_item_class.for_groups(recipient_groups, **invoice_item_attrs(invoice:))
  end

  def to_invoice_item_for_people(invoice: nil, recipient_people: Person.none)
    invoice_item_class.for_people(recipient_people, **invoice_item_attrs(invoice:))
  end

  def invoice_item_class
    "Invoice::#{self.class.name.gsub(/^PeriodInvoiceTemplate::/, "")}".constantize
  end

  def unit_cost
    return nil if dynamic_cost_parameters[:unit_cost].nil?
    BigDecimal(dynamic_cost_parameters[:unit_cost])
  rescue ArgumentError, TypeError
    errors.add(:unit_cost, :is_not_a_decimal_number)
    nil
  end

  def enforce_unit_cost_precision
    dynamic_cost_parameters[:unit_cost] = ActiveSupport::NumberHelper.number_to_currency(
      dynamic_cost_parameters[:unit_cost], format: "%n", delimiter: ""
    )
  end

  private

  def name_attrs
    attributes.with_indifferent_access
      .slice(:name, *Globalized.globalized_names_for_attr(:name, true))
  end

  def invoice_item_attrs(invoice: nil)
    name_attrs.merge(cost_center:, account:, vat_rate:, invoice:, unit_cost: unit_cost,
      dynamic_cost_parameters: dynamic_cost_parameters.merge({
        template_item_id: id,
        period_start_on: period_invoice_template.start_on,
        period_end_on: period_invoice_template.end_on
      }))
  end
end
