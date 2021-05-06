# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::Letter
  class Content < Section

    def render(recipient)
      render_salutation(recipient) if letter.salutation?
      stamped :render_content
    end

    private

    def render_content
      pdf.markup(letter.body.to_s)
    end

    def render_salutation(recipient)
      salutation = Salutation.new(recipient, letter.salutation)
      if generic?(salutation)
        stamped(:salutation_generic) { pdf.text salutation.value }
      else
        pdf.text salutation.value
      end
      pdf.move_down pdf.font_size * 2
    end

    def generic?(salutation)
      salutation.attributes.values.none?(&:present?) && letter.salutation == 'default'
    end
  end
end
