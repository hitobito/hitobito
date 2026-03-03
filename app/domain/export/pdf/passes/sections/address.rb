#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Passes::Sections
  # Renders the recipient address block with optional sender address.
  # Uses the same address positioning as Letter::Header to align with
  # Swiss Post windowed envelope standards.
  class Address
    include Export::Pdf::AddressRenderers
    include Export::Pdf::Concerns::GroupAddressLookup

    # Mirror Letter's margin so the address lands at the same page-absolute
    # x position regardless of whether the PDF itself has margins set.
    self.left_address_x = Export::Pdf::Messages::Letter::MARGIN
    self.right_address_x = 290 + Export::Pdf::Messages::Letter::MARGIN

    ADDRESS_BOX = [58.mm, 60].freeze
    ADDRESS_TOP = 60.mm

    SENDER_FONT_SIZE = 6
    RECIPIENT_FONT_SIZE = 10
    SEPARATOR_SPACING = 2.mm

    delegate :cursor, to: :@pdf

    def initialize(pdf, pass_decorator, card_layout = nil)
      @pdf = pdf
      @pass_decorator = pass_decorator
      @card_layout = card_layout
    end

    def render
      @pdf.move_cursor_to @pdf.bounds.top - ADDRESS_TOP + @pdf.page.margins[:top]
      @pdf.bounding_box(
        address_position(group.letter_address_position),
        width: ADDRESS_BOX.first, height: ADDRESS_BOX.second
      ) do
        render_sender_address
        @pdf.text person_address, size: RECIPIENT_FONT_SIZE, leading: 2
      end
    end

    private

    def group
      @pass_decorator.pass_definition.owner
    end

    def render_sender_address
      sender = sender_address
      return if sender.blank?

      @pdf.text sender, size: SENDER_FONT_SIZE, style: :italic, color: "666666"
      @pdf.stroke { @pdf.horizontal_line 0, ADDRESS_BOX.first }
      @pdf.move_down SEPARATOR_SPACING
    end

    def person_address
      Contactable::Address.new(@pass_decorator.person).for_letter
    end

    def sender_address
      parts = group_address_parts(group)
      parts.join(", ") if parts.present?
    end
  end
end
