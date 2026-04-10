#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Passes::Sections::Concerns
  # Shared rendering utilities for card sections (CardFront and CardBack).
  # Provides common methods for drawing backgrounds and managing fill colors.
  module CardRenderer
    private

    def draw_background
      @pdf.fill_color @pass_decorator.pdf_background_color
      @pdf.fill_rounded_rectangle(card_position, *@card_layout.dimensions,
        @card_layout.card_corner_radius)
      @pdf.fill_color "000000"
    end

    def with_color(color)
      @pdf.fill_color color
      yield
      @pdf.fill_color "000000"
    end

    def card_position
      raise NotImplementedError, "#{self.class} must implement #card_position"
    end
  end
end
