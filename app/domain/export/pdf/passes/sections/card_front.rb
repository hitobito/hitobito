#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Passes::Sections
  # Renders the front side of the pass card.
  # Displays the pass header with logo and title, member information
  # including photo and member number, and validity dates.
  # Uses adaptive text colors based on the background color luminance.
  class CardFront
    include Concerns::LogoRenderer
    include Concerns::CardRenderer

    CARD_PADDING = 4.mm

    # Layout constants
    HEADER_HEIGHT = 12.mm
    FOOTER_OFFSET = 2.mm
    LOGO_SPACING = 2.mm

    # Text box dimensions
    TITLE_HEIGHT = 9.mm
    TITLE_FONT_SIZE = 9
    NAME_HEIGHT = 5.mm
    NAME_FONT_SIZE = 10
    MEMBER_NUMBER_LABEL_HEIGHT = 3.mm
    MEMBER_NUMBER_LABEL_FONT_SIZE = 5
    MEMBER_NUMBER_VALUE_HEIGHT = 4.mm
    MEMBER_NUMBER_VALUE_FONT_SIZE = 8
    NAME_SPACING = 6.mm
    VALIDITY_HEIGHT = 8.mm
    VALIDITY_FONT_SIZE = 6

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
      render_header
      render_member_info
      render_validity_info
    end

    def calculate_content_bounds
      @inner_width = @card_layout.card_width - (2 * CARD_PADDING)
      @content_x = @card_layout.front_x + CARD_PADDING
      @content_top = @card_layout.card_y - CARD_PADDING
    end

    def render_header
      logo_w = render_logo(@content_x, @content_top)
      title_width = @inner_width - logo_w - ((logo_w > 0) ? LOGO_SPACING : 0)

      with_color(@pass_decorator.text_colors[:text]) do
        @pdf.text_box @pass_decorator.name,
          at: [@content_x, @content_top],
          width: title_width,
          height: TITLE_HEIGHT,
          size: TITLE_FONT_SIZE,
          style: :bold,
          overflow: :shrink_to_fit
      end
    end

    def render_member_info
      body_y = @content_top - HEADER_HEIGHT

      info_x = @content_x
      info_width = @inner_width

      render_member_name(info_x, body_y, info_width)
      render_member_number(info_x, body_y - NAME_SPACING, info_width)
    end

    def render_member_name(x, y, width)
      with_color(@pass_decorator.text_colors[:text]) do
        @pdf.text_box @pass_decorator.member_name,
          at: [x, y],
          width: width,
          height: NAME_HEIGHT,
          size: NAME_FONT_SIZE,
          style: :bold,
          overflow: :shrink_to_fit
      end
    end

    def render_member_number(x, y, width)
      render_member_number_label(x, y, width)
      render_member_number_value(x, y, width)
    end

    def render_member_number_label(x, y, width)
      with_color(@pass_decorator.text_colors[:label]) do
        @pdf.text_box I18n.t("activerecord.attributes.pass.member_number").upcase,
          at: [x, y],
          width: width,
          height: MEMBER_NUMBER_LABEL_HEIGHT,
          size: MEMBER_NUMBER_LABEL_FONT_SIZE,
          style: :bold
      end
    end

    def render_member_number_value(x, y, width)
      with_color(@pass_decorator.text_colors[:text]) do
        @pdf.text_box @pass_decorator.member_number.to_s,
          at: [x, y - MEMBER_NUMBER_LABEL_HEIGHT],
          width: width,
          height: MEMBER_NUMBER_VALUE_HEIGHT,
          size: MEMBER_NUMBER_VALUE_FONT_SIZE,
          overflow: :shrink_to_fit
      end
    end

    def render_validity_info
      return if @pass_decorator.valid_until.blank?

      label = I18n.t("activerecord.attributes.pass.valid_until")
      validity_line = "#{label} #{I18n.l(@pass_decorator.valid_until)}"
      footer_y = @card_layout.card_y - @card_layout.card_height + CARD_PADDING + FOOTER_OFFSET

      with_color(@pass_decorator.text_colors[:muted]) do
        @pdf.text_box validity_line,
          at: [@content_x + (@inner_width / 2), footer_y],
          width: @inner_width / 2,
          height: VALIDITY_HEIGHT,
          size: VALIDITY_FONT_SIZE,
          align: :right,
          overflow: :shrink_to_fit
      end
    end

    def card_position
      @card_layout.front_position
    end
  end
end
