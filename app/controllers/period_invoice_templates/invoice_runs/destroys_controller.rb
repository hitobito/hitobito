# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplates::InvoiceRuns::DestroysController < InvoiceRuns::DestroysController
  private

  def destroy_return_path(_destroyed, _options = {})
    group_period_invoice_template_invoice_runs_path(entry.group, entry.period_invoice_template)
  end
end
