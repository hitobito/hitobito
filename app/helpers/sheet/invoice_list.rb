# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.


module Sheet
  class InvoiceList < Sheet::Invoice

    def title
      ::InvoiceList.model_name.human(count: 2)
    end

    def render_left_nav
      view.render('invoices/nav_left')
    end
  end
end
