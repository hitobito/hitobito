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
      logo_data = @pass_decorator.logo_blob
      return 0 unless logo_data

      logo_x = (align == :right) ? x + @inner_width - LOGO_MAX_WIDTH : x

      @pdf.image(StringIO.new(logo_data),
        at: [logo_x, y],
        fit: [LOGO_MAX_WIDTH, LOGO_MAX_HEIGHT])

      LOGO_MAX_WIDTH
    rescue StandardError
      0
    end

    def logo_available?
      @pass_decorator.logo_blob.present?
    end
  end
end
