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
      @receiver_address_data ||= if invoice.recipient_address_values.empty?
        deprecated_receiver_address_data
      else
        invoice.recipient_address_values
      end.map { |v| [v] }
    end

    def deprecated_receiver_address_data
      # Old invoices do not have recipient_address_values, why we have to use the old address
      invoice.deprecated_recipient_address&.split("\n")&.compact_blank&.take(3) || []
    end

    def table(table, options)
      pdf.table(table, options) if table.present?
    end
  end
end
