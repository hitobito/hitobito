#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Passes::Sections
  # Renders the back side of the pass card.
  # Displays a QR code, the pass description (if present),
  # and the pass title in uppercase.
  # Uses adaptive text colors based on the background color luminance.
  class CardBack
    include Concerns::CardRenderer

    CARD_PADDING = 4.mm

    # QR code dimensions
    QR_SIZE = 30.mm
    QR_STROKE_WIDTH = 1
    QR_TOP_OFFSET = 8.mm
    QR_CORNER_RADIUS = 2.mm

    # Description dimensions
    DESCRIPTION_OFFSET = 2.mm
    DESCRIPTION_HEIGHT = 8.mm
    DESCRIPTION_FONT_SIZE = 7

    # Title dimensions
    TITLE_BOTTOM_OFFSET = 5.mm
    TITLE_SPACING = 5.mm
    TITLE_HEIGHT = 4.mm
    TITLE_FONT_SIZE = 7

    def initialize(pdf, pass_decorator, card_layout)
      @pdf = pdf
      @pass_decorator = pass_decorator
      @card_layout = card_layout
    end

    def render
      draw_background
      render_content
    end

    private

    def render_content
      calculate_content_bounds
      render_qr
      render_description
      render_title
    end

    def calculate_content_bounds
      @inner_width = @card_layout.card_width - (2 * CARD_PADDING)
      @content_x = @card_layout.back_x + CARD_PADDING
      @center_x = @card_layout.back_x + (@card_layout.card_width / 2)
    end

    def render_qr
      qr_code = Passes::VerificationQrCode.new(@pass_decorator).generate
      qr_image = qr_code.as_png(fill: "ffffff00", border_modules: 5).to_blob

      @pdf.fill_color "ffffff"
      @pdf.fill_rounded_rectangle(qr_position, QR_SIZE, QR_SIZE, QR_CORNER_RADIUS)

      @pdf.image(StringIO.new(qr_image),
        at: qr_position,
        width: QR_SIZE,
        height: QR_SIZE)
    end

    def render_description
      return if @pass_decorator.description.blank?

      desc_y = qr_y_position - QR_SIZE - DESCRIPTION_OFFSET

      with_color(@pass_decorator.text_colors[:muted]) do
        @pdf.text_box @pass_decorator.description,
          at: [@content_x, desc_y],
          width: @inner_width,
          height: DESCRIPTION_HEIGHT,
          size: DESCRIPTION_FONT_SIZE,
          align: :center,
          overflow: :shrink_to_fit
      end
    end

    def qr_position
      [qr_x_position, qr_y_position]
    end

    def qr_x_position
      @center_x - (QR_SIZE / 2)
    end

    def qr_y_position
      @card_layout.card_y - QR_TOP_OFFSET
    end

    def render_title
      title_y = @card_layout.card_y - @card_layout.card_height + TITLE_BOTTOM_OFFSET + TITLE_SPACING

      with_color(@pass_decorator.text_colors[:label]) do
        @pdf.text_box @pass_decorator.name.upcase,
          at: [@content_x, title_y],
          width: @inner_width,
          height: TITLE_HEIGHT,
          size: TITLE_FONT_SIZE,
          align: :center,
          style: :bold,
          overflow: :shrink_to_fit
      end
    end

    def card_position
      @card_layout.back_position
    end
  end
end
