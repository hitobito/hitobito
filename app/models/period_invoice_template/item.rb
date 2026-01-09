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
# In order to actually calculate counts and prices, the #to_invoice_item method
# is used to get an invoice item that can perform the calculation.
class PeriodInvoiceTemplate::Item < ActiveRecord::Base
  serialize :dynamic_cost_parameters, type: Hash, coder: YAML
  belongs_to :period_invoice_template

  # This base class may not be instantiated
  validates :type, exclusion: { in: %w(PeriodInvoiceTemplate::Item) }

  def dynamic_cost_parameter_definitions
    invoice_item_class.dynamic_cost_parameter_definitions
  end

  def to_invoice_item
    invoice_item_class
      .new(name:, cost_center:, account:,
        dynamic_cost_parameters: dynamic_cost_parameters.merge({
          group_id: period_invoice_template.group_id,
          period_start_on: period_invoice_template.period_start_on,
          period_end_on: period_invoice_template.period_end_on,
        }))
  end

  def invoice_item_class
    "Invoice::#{self.class.name.gsub(/^PeriodInvoiceTemplate::/, '')}".constantize
  end
end
