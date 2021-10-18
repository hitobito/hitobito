# frozen_string_literal: true

#  Copyright (c) 2020-2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::Letter
  class Content < Section

    def render(recipient)
      offset_cursor_from_top 117.5.mm
      render_salutation(recipient) if letter.salutation?
      stamped :render_content
    end

    private

    def render_content
      pdf.markup(letter.body.to_s)
    end

    def render_salutation(recipient)
      pdf.text recipient.salutation if recipient.salutation.present?
      pdf.move_down pdf.font_size * 2
    end

  end
end
