# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::InvoiceItems
  class Row < Export::Tabular::Row
    include ActionView::Helpers::NumberHelper

    (List::INVOICE_ATTRS + List::ADDRESS_ATTRS).each do |attr|
      define_method(attr) { invoice.public_send(attr) }
    end

    def state
      invoice.state_label
    end

    def unit_cost
      with_precision(entry.unit_cost)
    end

    def cost
      entry.recalculate if entry.cost.nil?
      with_precision(entry.cost)
    end

    def vat
      with_precision(entry.vat)
    end

    def total
      with_precision(entry.total)
    end

    private

    def invoice
      entry.invoice
    end

    def with_precision(number)
      number_with_precision(number)
    end
  end
end
