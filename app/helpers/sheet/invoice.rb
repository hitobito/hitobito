# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Invoice < Base
    def title
      return ::Invoice.model_name.human(count: 2) unless invoice_run
      if entry
        [entry.title, invoice_run.recipient_source_label].compact.join(" - ")
      else
        [invoice_run.title, invoice_run.recipient_source_label].compact.join(" - ")
      end
    end

    def parent_sheet
      @parent_sheet ||= begin
        parent_sheet_class = if period_invoice_template
          Sheet::PeriodInvoiceTemplate
        elsif invoice_run
          Sheet::InvoiceRun
        else
          Sheet::Group
        end

        create_parent(parent_sheet_class)
      end
    end

    def left_nav?
      true
    end

    def render_left_nav
      view.render("invoices/nav_left")
    end

    private

    def invoice_run
      @invoice_run ||= ::InvoiceRun.find_by(id: view.params[:invoice_run_id])
    end

    def period_invoice_template
      @period_invoice_template ||= ::PeriodInvoiceTemplate
        .find_by(id: view.params[:period_invoice_template_id])
    end
  end
end
