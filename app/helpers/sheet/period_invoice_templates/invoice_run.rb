#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  module PeriodInvoiceTemplates
    class InvoiceRun < Sheet::Invoice
      def parent_sheet
        @parent_sheet ||= create_parent(Sheet::PeriodInvoiceTemplate)
      end

      def title
        entry ? entry.title : ::InvoiceRun.model_name.human(count: 2)
      end

      def parent_link_url
        unless no_invoice_or_shared_title?
          return view.group_invoice_run_invoices_path(entry.group,
            entry)
        end
        super
      end

      def no_invoice_or_shared_title?
        !child.entry || (child.title == entry.title)
      end
    end
  end
end
