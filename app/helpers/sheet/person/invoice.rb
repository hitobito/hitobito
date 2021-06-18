# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Person < Base
    class Invoice < Base

      self.parent_sheet = Sheet::Person

      def left_nav?
        true
      end

      def render_left_nav
        view.render('invoices/nav_left')
      end

    end
  end
end
