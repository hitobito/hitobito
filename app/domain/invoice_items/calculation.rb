# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoiceItems
  class Calculation
    def self.round(decimal)
      (decimal / Invoice::ROUND_TO).round * Invoice::ROUND_TO
    end

    def calculate_total_cost_and_vat(invoice_items)
      [:total, :cost, :vat].index_with do |field|
        # rubocop:todo Layout/LineLength
        self.class.round(invoice_items.reject(&:frozen?).map(&field).compact.sum(BigDecimal("0.00")))
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
