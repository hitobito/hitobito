# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


class InvoiceDecorator < ApplicationDecorator
  decorates :invoice

  def cost
    h.number_to_currency(calculated[:cost], format: '%n %u')
  end

  def vat
    h.number_to_currency(calculated[:vat], format: '%n %u')
  end

  def total
    h.number_to_currency(model.total || calculated[:total], format: '%n %u')
  end

end
