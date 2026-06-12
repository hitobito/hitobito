# frozen_string_literal: true

#  Copyright (c) 2026-2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Payment < Base
    def title
      ::Payment.model_name.human(count: 2)
    end

    def parent_sheet
      @parent_sheet ||= create_parent(parent_sheet_class)
    end

    def left_nav?
      true
    end

    def render_left_nav
      view.render("invoices/nav_left")
    end

    private

    def parent_sheet_class
      invoice ? Sheet::Invoice : Sheet::Group
    end

    def invoice
      @invoice ||= ::Invoice.find_by(id: view.params[:invoice_id])
    end
  end
end
