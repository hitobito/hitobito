#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class ReceiverAddress < Section
    include Export::Pdf::AddressRenderers
    include Export::Pdf::ShippingInfoRenderers

    def render
      float do
        offset_cursor_from_top 5.1.cm
        bounding_box(address_position(invoice.letter_address_position), width: address_box_width) do
          unless shipping_info_empty?(invoice)
            render_shipping_info(invoice, width: address_box_width)
            pdf.move_down 4.mm
          end
          table(receiver_address_data, cell_style: {borders: [], padding: [0, 0, 0, 0]})
        end
      end
    end
  end
end
