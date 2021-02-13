# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.


module Sheet
  class InvoiceList < Sheet::Base

    def title
      if entry && !entry.receiver
        ::Invoice.model_name.human
      else
        ::InvoiceList.model_name.human(count: 2)
      end
    end

    def left_nav?
      true
    end

    def render_left_nav
      if form?
        parent_sheet.render_left_nav
      else
        view.render("invoices/nav_left")
      end
    end

    # Needs spacing because parent has no tabs
    def render_parent_title
      content_tag(:div, super, style: "padding-bottom: 1em")
    end

    def link_url
      view.group_invoice_lists_path(view.group, returning: true)
    end

    def parent_sheet
      create_parent(Sheet::Group) if form?
    end

    def form?
      %w(new create).include?(view.action_name)
    end

  end
end
