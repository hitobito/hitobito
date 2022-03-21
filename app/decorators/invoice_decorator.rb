# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


class InvoiceDecorator < ApplicationDecorator
  decorates :invoice

  def cost
    format_currency(calculated[:cost])
  end

  def vat
    format_currency(calculated[:vat])
  end

  def total
    format_currency(model.total || calculated[:total])
  end

  def amount_open
    format_currency(model.amount_open)
  end

  def amount_paid
    format_currency(model.amount_paid)
  end

  def format_currency(amount)
    ActiveSupport::NumberHelper.number_to_currency(amount, { unit: currency, format: '%n %u' })
  end

  def currency
    model.new_record? ? model.invoice_config.currency : model.currency
  end

  def as_quicksearch
    { id: id, label: h.h(model.to_s), type: :invoice, icon: :'file-invoice' }
  end

end
