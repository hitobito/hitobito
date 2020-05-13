# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class Header < Section

    def render
      bounding_box([0, cursor + 30], width: bounds.width, height: 100) do
        text invoice.address
      end
    end
  end
end
