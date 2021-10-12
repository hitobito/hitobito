# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
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
      salutation = salutation(recipient.person)

      if recipient.household_address
        salutation_text = household_salutations(recipient)
      elsif generic?(salutation)
        stamped(:salutation_generic) { pdf.text salutation.value }
      else
        salutation_text = salutation.value
      end

      pdf.text salutation_text if salutation_text.present?
      pdf.move_down pdf.font_size * 2
    end

    def generic?(salutation)
      salutation.attributes.values.none?(&:present?) && letter.salutation == 'default'
    end

    def salutation(person)
      Salutation.new(person, letter.salutation)
    end

    def household_salutations(recipient)
      household_people(recipient).collect do |r|
        salutation(r.person).value
      end.join(', ')
    end

    def household_people(recipient)
      letter
        .message_recipients
        .joins(:person)
        .where('people.household_key': recipient.person.household_key)
    end
  end
end
