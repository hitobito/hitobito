#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class Header < Section
    include Export::Pdf::AddressRenderers

    LOGO_WIDTH = 150.mm
    LOGO_HEIGHT = 16.mm
    HEADER_MARGIN = 30

    def render
      prepare_header_space

      render_logo if invoice.invoice_config.logo_enabled?

      render_shipping_info
      render_address
    end

    private

    def prepare_header_space
      move_cursor_to cursor + HEADER_MARGIN
    end

    def render_address
      bounding_box(address_x_position, width: bounds.width, height: 100) do
        text invoice.address
      end
    end

    def render_logo
      float do
        Export::Pdf::Logo.new(
          pdf,
          invoice.invoice_config.logo,
          image_width: LOGO_WIDTH,
          image_height: LOGO_HEIGHT,
          position: invoice.logo_position.to_sym
        ).render
      end
    end

    def address_x_position
      address_position((invoice.logo_position == "left") ? "right" : "left")
    end

    def render_shipping_info
      if invoice.pp_post.present? || !invoice.own?
        pdf.move_down 36.mm
        render_shipping_info_post_logo unless invoice.own?
        render_shipping_info_text
        render_shipping_info_line
      end
    end

    def render_shipping_info_text
      shipping_method, text_height = shipping_methods[invoice.shipping_method.to_sym]
      text = "#{shipping_method}<font size='8'>#{invoice.pp_post}</font>"
      position = [0, cursor + (text_height * 0.75)]
      text_box(text, inline_format: true, overflow: :truncate, single_line: true, at: position)
    end

    def render_shipping_info_line
      pdf.move_down 4.mm
      pdf.stroke do
        pdf.horizontal_line 0, 58.mm
      end
    end

    def render_shipping_info_post_logo(width: 58.mm)
      text_box("Post CH AG", align: :center, size: 7.pt, width: width, at: [0, cursor + 12.pt])
    end

    def shipping_methods
      {
        own: ["", 8.pt],
        normal: ["<b><font size='12'>P.P.</font></b> ", 12.pt],
        priority: ["<b><font size='12'>P.P.</font> <font size='24pt'>A</font></b> ", 24.pt]
      }
    end
  end
end
