#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export
  module Pdf
    module Passes
      # Default PDF template for passes.
      # Renders a pass card with address block, crop marks, and front/back cards
      # in a side-by-side layout suitable for printing and folding.
      class Default
        MARGIN = [0, 0, 0, 0].freeze
        FONT = "NotoSans"

        # ISO ID-1 card dimensions (credit card size)
        CARD_WIDTH = 85.6.mm
        CARD_HEIGHT = 53.98.mm
        CARD_RADIUS = 3.mm
        CARD_GAP = 0.mm
        # Distance from the bottom page edge to the bottom of the card.
        CARD_BOTTOM_MARGIN = 25.mm

        # Crop marks
        CROP_MARK_LENGTH = 5.mm
        CROP_MARK_OFFSET = 2.mm

        Layout = Struct.new(:pdf_bounds) do
          def front_x = (pdf_bounds.width - (CARD_WIDTH * 2 + CARD_GAP)) / 2

          def back_x = front_x + CARD_WIDTH + CARD_GAP

          def card_y = CARD_BOTTOM_MARGIN + CARD_HEIGHT

          def card_width = CARD_WIDTH

          def card_height = CARD_HEIGHT

          def card_corner_radius = CARD_RADIUS

          def crop_mark_length = CROP_MARK_LENGTH

          def crop_mark_offset = CROP_MARK_OFFSET

          def front_position = [front_x, card_y]

          def back_position = [back_x, card_y]

          def dimensions = [card_width, card_height]
        end

        def initialize(pass)
          @pass_decorator = pass.decorate
        end

        def render
          pdf.font FONT
          sections.each(&:render)
          pdf.render
        end

        def filename
          parts = ["pass", @pass_decorator.name.parameterize(separator: "_")]
          parts << @pass_decorator.person.full_name.parameterize(separator: "_")
          [parts.join("-"), :pdf].join(".")
        end

        private

        def pdf
          @pdf ||= Export::Pdf::Document.new(
            page_size: "A4", page_layout: :portrait, margin: MARGIN
          ).pdf
        end

        def layout
          @layout ||= Layout.new(pdf.bounds)
        end

        def sections
          @sections ||= section_classes.map { |klass| klass.new(pdf, @pass_decorator, layout) }
        end

        def section_classes
          [Sections::Address, Sections::CropMarks, Sections::CardFront, Sections::CardBack]
        end
      end
    end
  end
end
