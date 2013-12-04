# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Admin < Base
    def render_main_tabs
      view.tab_bar(current_nav_path) do |bar|
        view.render('shared/admin_tabs', bar: bar)
      end
    end
  end
end
