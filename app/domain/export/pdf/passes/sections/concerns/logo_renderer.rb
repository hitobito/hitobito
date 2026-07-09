#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Passes::Sections::Concerns
  # Shared module for rendering logos in PDF pass sections.
  # Handles logo retrieval, sizing, and positioning.
  module LogoRenderer
    LOGO_MAX_WIDTH = 20.mm
    LOGO_MAX_HEIGHT = 9.mm

    private

    def render_logo(x, y, align: :right)
      logo_data = fetch_logo_data
      return 0 unless logo_data

      logo_x = calculate_logo_x(x, align)
      @pdf.image(StringIO.new(logo_data),
        at: [logo_x, y],
        fit: [LOGO_MAX_WIDTH, LOGO_MAX_HEIGHT])

      LOGO_MAX_WIDTH
    end

    def fetch_logo_data
      attachment = @pass_decorator.logo_banner(@pass_decorator.person.language)
      attachment&.variant(resize_to_fit: [1032, 336], format: :png)&.processed&.download
    end

    def calculate_logo_x(x, align)
      return x + @inner_width - LOGO_MAX_WIDTH if align == :right
      x
    end
  end
end
