# encoding: utf-8

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Message
  class Header < Section

    def render(recipient)
      bounding_box([0, cursor], width: bounds.width, height: 40) do
        render_image
      end
      bounding_box([bounds.width / 2 + 20, cursor], width: bounds.width / 2 - 20, height: 40) do
        text sanitize(recipient.target)
      end
      pdf.move_down 20
    end

    private

    def render_image; end

  end
end
