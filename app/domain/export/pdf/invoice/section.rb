# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class Section < Export::Pdf::Section

    delegate :invoice_items, :address, :with_reference?, :participant_number, to: :invoice

    alias_method :invoice, :model

    private

    def helper
      @helper ||= Class.new do
        include ActionView::Helpers::NumberHelper
      end.new
    end

    def receiver_address_data
      @receiver_address_data ||= tabelize(invoice.recipient_address)
    end

    def tabelize(string)
      string.to_s.split(/\n/).reject(&:blank?).collect { |ra| [ra] }
    end

    def table(table, options)
      pdf.table(table, options) if table.present?
    end
  end
end
