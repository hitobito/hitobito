# frozen_string_literal: true

#  Copyright (c) 2012-2026, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplate::RoleCountItem < PeriodInvoiceTemplate::Item
  validates :role_types, presence: true
  validates :unit_cost, money: true

  def role_types
    dynamic_cost_parameters[:role_types] || []
  end

  def unit_cost
    BigDecimal(dynamic_cost_parameters[:unit_cost])
  rescue ArgumentError, TypeError
    errors.add(:unit_cost, :is_not_a_decimal_number)
    BigDecimal(0)
  end
end
