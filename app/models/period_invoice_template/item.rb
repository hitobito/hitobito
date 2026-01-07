# frozen_string_literal: true

#  Copyright (c) 2012-2026, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplate::Item < ActiveRecord::Base
  attr_reader :fee, :key, :unit_cost, :layer_group_ids

  def initialize(fee:, key:, unit_cost:, layer_group_ids: nil)
    @fee = fee
    @key = key
    @unit_cost = unit_cost
    @layer_group_ids = layer_group_ids
  end

  def present? = count.positive?

  def count = @count ||= models.count

  def total_cost = count * unit_cost

  def to_invoice_item
    Invoice::CalculatedItem
      .new(name: key, unit_cost:, count:, dynamic_cost_parameters: {fixed_fees: fee})
      .tap(&:recalculate)
  end

  def models
    scope.then { |scope| layer_group_ids ? with_matching_layer_group(scope) : scope }
  end

  protected

  def with_matching_layer_group(scope)
    scope.where(groups: {layer_group_id: layer_group_ids})
  end
end
