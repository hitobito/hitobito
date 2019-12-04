# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Invoices
  class Row < Export::Tabular::Row
    include ActionView::Helpers::NumberHelper

    def state
      entry.state_label
    end

    def cost
      with_precision(entry.calculated[:cost])
    end

    def vat
      with_precision(entry.calculated[:vat])
    end

    def amount_paid
      with_precision(entry.amount_paid)
    end

    def total
      with_precision(entry.total)
    end

    def with_precision(number)
      number_with_precision(number, precision: 2)
    end
  end

end
