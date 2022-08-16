# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class ReceiverAddress < Section

    def render
      float do
        bounding_box(address_position, width: bounds.width, height: 80) do
          table(receiver_address_data, cell_style: { borders: [], padding: [0, 0, 0, 0] })
        end
      end
    end

    private

    def address_position
      x_coords = {
        left: 0,
        right: 290
      }[invoice.group.settings(:messages_letter).address_position&.to_sym]
      x_coords ||= 0
      [x_coords, 640]
    end
  end
end
