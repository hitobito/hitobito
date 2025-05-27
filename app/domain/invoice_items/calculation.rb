# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoiceItems
  class Calculation
    attr_reader :invoice_items

    def initialize(invoice_items)
      @invoice_items = invoice_items
    end

    def calculated
      @calculated ||= [:total, :cost, :vat].index_with do |field|
        round(invoice_items.reject(&:frozen?).map(&field).compact.sum(BigDecimal("0.00")))
      end
    end

    private

    def round(decimal)
      (decimal / Invoice::ROUND_TO).round * Invoice::ROUND_TO
    end
  end
end
