#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceItemDecorator < ApplicationDecorator
  decorates :invoice_item

  def cost
    format_currency(model.cost)
  end

  def unit_cost
    format_currency(model.unit_cost)
  end

  def vat_rate
    h.number_to_percentage(model.vat_rate || 0)
  end

  def total
    format_currency(model.total)
  end

  def format_currency(value)
    invoice.decorate.format_currency(value)
  end
end
