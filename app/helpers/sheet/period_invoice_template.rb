#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class PeriodInvoiceTemplate < Sheet::Invoice
    def title
      entry&.name || ::PeriodInvoiceTemplate.model_name.human(count: 2)
    end

    tab "period_invoice_templates.tabs.info",
      :group_period_invoice_template_path,
      if: ->(_, _, entry) { entry.present? }

    tab "period_invoice_templates.tabs.invoice_runs",
      :group_period_invoice_template_invoice_runs_path,
      if: ->(_, _, entry) { entry.present? }
  end
end
