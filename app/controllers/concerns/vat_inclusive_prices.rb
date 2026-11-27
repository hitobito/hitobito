# frozen_string_literal: true

#  Copyright (c) 2026, florist.ch. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module VatInclusivePrices
  extend ActiveSupport::Concern

  included do
    helper_method :prices_include_vat?
  end

  private

  def prices_include_vat?
    group.layer_group.invoice_config.prices_include_vat?
  end

  def convert_unit_costs_to_net(items_attributes)
    items_attributes&.each_value { |attrs| convert_unit_cost_to_net(attrs) }
  end

  def convert_unit_cost_to_net(attrs, vat_rate = attrs[:vat_rate])
    return unless prices_include_vat? && attrs&.key?(:unit_cost)

    attrs[:unit_cost] = Invoice::VatInclusivePrice.net(attrs[:unit_cost], vat_rate)
  end
end
