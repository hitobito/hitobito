#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class Header < Section
    include Export::Pdf::AddressRenderers

    LOGO_WIDTH = 150.mm
    LOGO_HEIGHT = 16.mm
    HEADER_MARGIN = 20

    def render
      prepare_header_space

      render_logo if invoice.invoice_config.logo_enabled?

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
  end
end
