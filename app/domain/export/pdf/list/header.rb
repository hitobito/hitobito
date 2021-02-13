#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::List
  class Header < Section
    def render
      bounding_box([0, cursor], width: bounds.width, height: 40) do
        font_size(20) do
          text group.name, style: :bold, width: bounds.width - 80
        end
        render_image
      end
    end

    private

    def render_image
    end
  end
end
