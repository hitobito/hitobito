# frozen_string_literal: true

#  Copyright (c) 2022, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Payments
  class List < Export::Tabular::Base

    self.model_class = Payment
    self.row_class = Export::Tabular::Payments::Row

    INCLUDED_ATTRS = %w(id amount received_at reference
                        transaction_identifier status).freeze


    CUSTOM_METHODS = %w(payee_person_name payee_person_address)

    def attributes
      INCLUDED_ATTRS + CUSTOM_METHODS
    end

  end
end
