# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Export::Tabular::Invoices
  class EvaluationRow < Export::Tabular::Row
    include ActionView::Helpers::NumberHelper
    WITH_PRECISION_ATTRS = [:vat, :amount_paid]


    private
    
    def value_for(attr)
      value = entry.send(:[], attr)

      return number_with_precision(value) if WITH_PRECISION_ATTRS.include?(attr)

      value
    end

  end
end
