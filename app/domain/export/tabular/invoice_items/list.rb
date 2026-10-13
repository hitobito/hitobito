# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::InvoiceItems
  class List < Export::Tabular::Base
    ITEM_ATTRS = %w[name account cost_center count unit_cost cost vat_rate vat total].freeze

    INVOICE_ATTRS = (Export::Tabular::Invoices::List::INCLUDED_ATTRS -
      %w[cost vat total amount_paid]).freeze

    ADDRESS_ATTRS = Export::Tabular::Invoices::List::ADDRESS_ATTRS.freeze

    RECIPIENT_ATTRS = ADDRESS_ATTRS.grep(/\Arecipient_/).freeze

    self.model_class = InvoiceItem
    self.row_class = Export::Tabular::InvoiceItems::Row

    def attributes
      (ITEM_ATTRS + INVOICE_ATTRS + ADDRESS_ATTRS).collect(&:to_sym)
    end

    private

    def human_attribute(attr)
      return super if ITEM_ATTRS.include?(attr.to_s)
      return recipient_label(attr) if RECIPIENT_ATTRS.include?(attr.to_s)

      Invoice.human_attribute_name(attr)
    end

    def recipient_label(attr)
      [Invoice.human_attribute_name(:recipient), Invoice.human_attribute_name(attr)].join(" ")
    end
  end
end
