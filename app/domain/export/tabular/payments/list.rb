# frozen_string_literal: true

#  Copyright (c) 2022, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Payments
  class List < Export::Tabular::Base

    self.model_class = Payment
    self.row_class = Export::Tabular::Payments::Row

    EXCLUDED_ATTRS = %w(invoice_id transaction_xml)

    def attributes
      model_class.column_names - EXCLUDED_ATTRS
    end

  end
end
