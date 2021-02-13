# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class InvoiceInformation < Section

    def render
      bounding_box([0, 640], width: bounds.width, height: 80) do
        table(information, cell_style: { borders: [], padding: [1, 20, 0, 0] })
      end
    end

    private

    def information
      information_hash.map do |k, v|
        labeled_information(k, v)
      end.compact
    end

    def information_hash
      {
        invoice_number: invoice.sequence_number,
        invoice_date: (I18n.l(invoice.issued_at) if invoice.issued_at),
        due_at: (I18n.l(invoice.due_at) if invoice.due_at),
        creator: invoice.creator.try(:full_name),
        vat_number: invoice.vat_number
      }
    end

    def labeled_information(attr, value)
      return if value.blank?
      [I18n.t("invoices.pdf.#{attr}") + ":", value]
    end
  end
end
