# frozen_string_literal: true

#  Copyright (c) 2012-2024, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Sheet
  class InvoiceList < Base
    def title
      return ::InvoiceList.model_name.human(count: 2) if child && no_invoice_or_shared_title?
      return entry.title if child&.entry
      super
    end

    def parent_sheet
      create_parent(Sheet::Group)
    end

    def parent_link_url
      unless no_invoice_or_shared_title?
        return view.group_invoice_list_invoices_path(entry.group,
          entry)
      end
      super
    end

    def left_nav?
      true
    end

    def render_left_nav
      view.render("invoices/nav_left")
    end

    # Needs spacing because parent has no tabs
    def render_parent_title
      content_tag(:div, super, class: "pb-3")
    end

    def link_url
      view.group_invoice_lists_path(view.group, returning: true)
    end

    def no_invoice_or_shared_title?
      !child.entry || (child.title == entry.title)
    end
  end
end
