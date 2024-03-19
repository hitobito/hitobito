# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Invoice < Base
    def title
      if invoice_list
        invoice_list.title
      else
        ::Invoice.model_name.human(count: 2)
      end
    end

    def parent_sheet
      @parent_sheet ||= begin
        parent_sheet_class = invoice_list ? Sheet::InvoiceList : Sheet::Group
        create_parent(parent_sheet_class)
      end
    end

    def left_nav?
      true
    end

    def render_left_nav
      view.render('invoices/nav_left')
    end

    private

    def invoice_list
      @invoice_list ||= ::InvoiceList.find_by(id: view.params[:invoice_list_id])
    end
  end
end
