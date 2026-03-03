#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Passes::Sections
  # Renders the back side of the pass card.
  # Displays a QR code placeholder, the pass description (if present),
  # and the pass title in uppercase.
  # Uses adaptive text colors based on the background color luminance.
  class CardBack
    include Concerns::CardRenderer

    CARD_PADDING = 4.mm

    # QR code dimensions
    QR_SIZE = 25.mm
    QR_STROKE_WIDTH = 1
    QR_TOP_OFFSET = 6.mm
    QR_CORNER_RADIUS = 2.mm
    QR_LABEL_OFFSET = 2.mm
    QR_LABEL_HEIGHT = 4.mm
    QR_LABEL_FONT_SIZE = 8

    # Description dimensions
    DESCRIPTION_OFFSET = 3.mm
    DESCRIPTION_HEIGHT = 8.mm
    DESCRIPTION_FONT_SIZE = 6

    # Title dimensions
    TITLE_BOTTOM_OFFSET = 4.mm
    TITLE_SPACING = 5.mm
    TITLE_HEIGHT = 4.mm
    TITLE_FONT_SIZE = 5

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
      render_qr_placeholder
      render_description
      render_title
    end

    def calculate_content_bounds
      @inner_width = @card_layout.card_width - (2 * CARD_PADDING)
      @content_x = @card_layout.back_x + CARD_PADDING
      @center_x = @card_layout.back_x + (@card_layout.card_width / 2)
    end

    def render_qr_placeholder
      qr_x = @center_x - (QR_SIZE / 2)
      @qr_y = @card_layout.card_y - QR_TOP_OFFSET

      draw_qr_background(qr_x)
      draw_qr_border(qr_x)
      draw_qr_label(qr_x)
    end

    def draw_qr_background(qr_x)
      with_color(@pass_decorator.text_colors[:text]) do
        @pdf.fill_rounded_rectangle([qr_x, @qr_y], QR_SIZE, QR_SIZE, QR_CORNER_RADIUS)
      end
    end

    def draw_qr_border(qr_x)
      @pdf.stroke_color @pass_decorator.text_colors[:muted]
      @pdf.line_width = QR_STROKE_WIDTH
      @pdf.stroke_rounded_rectangle([qr_x, @qr_y], QR_SIZE, QR_SIZE, QR_CORNER_RADIUS)
      @pdf.stroke_color "000000"
    end

    def draw_qr_label(qr_x)
      with_color(@pass_decorator.text_colors[:label]) do
        @pdf.text_box "QR",
          at: [qr_x, @qr_y - (QR_SIZE / 2) + QR_LABEL_OFFSET],
          width: QR_SIZE,
          height: QR_LABEL_HEIGHT,
          size: QR_LABEL_FONT_SIZE,
          align: :center
      end
    end

    def render_description
      return if @pass_decorator.description.blank?

      desc_y = @qr_y - QR_SIZE - DESCRIPTION_OFFSET

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
