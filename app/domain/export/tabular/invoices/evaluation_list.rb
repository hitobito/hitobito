# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Export::Tabular::Invoices
  class EvaluationList < Export::Tabular::Base

    ATTRS = %w(name vat count amount_paid account cost_center).freeze

    self.row_class = Export::Tabular::Invoices::EvaluationRow

    def attributes
      ATTRS.collect(&:to_sym)
    end

    def attribute_label(attr)
      I18n.t("invoices.evaluations.show.table.#{attr}")
    end
  end
end
