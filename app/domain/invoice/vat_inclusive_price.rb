# frozen_string_literal: true

#  Copyright (c) 2026, florist.ch. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Invoice::VatInclusivePrice
  module_function

  def net(gross, vat_rate)
    price = decimal(gross)
    return gross unless price

    (price / vat_factor(vat_rate)).round(2)
  end

  def gross(net, vat_rate)
    return if net.nil?

    (net * vat_factor(vat_rate)).round(2)
  end

  def vat_factor(vat_rate)
    1 + (decimal(vat_rate) || 0) / 100
  end

  def decimal(value)
    BigDecimal(value.to_s)
  rescue ArgumentError
    nil
  end
end
