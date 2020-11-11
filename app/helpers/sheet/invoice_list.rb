# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.


module Sheet
  class InvoiceList < Sheet::Base

    def title
      ::InvoiceList.model_name.human(count: 2)
    end

    def left_nav?
      true
    end

    def render_left_nav
      view.render('invoices/nav_left')
    end

    # Needs spacing because parent has no tabs
    def render_parent_title
      content_tag(:div, super, style: 'padding-bottom: 1em')
    end

    def link_url
      view.group_invoice_lists_path(view.group, returning: true)
    end

  end
end
