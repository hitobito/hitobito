# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Invoices
  class List < Export::Tabular::Base
    INCLUDED_ATTRS = %w(title sequence_number state esr_number description
                        recipient_email recipient_address sent_at due_at
                        cost vat total amount_paid).freeze

    CUSTOM_METHODS = %w(cost_centers accounts payments)

    self.model_class = Invoice
    self.row_class = Export::Tabular::Invoices::Row

    def attributes
      (INCLUDED_ATTRS + CUSTOM_METHODS).collect(&:to_sym)
    end
  end
end
