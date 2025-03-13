# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Reporting < Base
    def left_nav?
      true
    end

    def render_left_nav
      NavLeft.new(self).render
    end

    private
  end
end
