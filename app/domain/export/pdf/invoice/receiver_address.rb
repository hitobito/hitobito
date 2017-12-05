# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class ReceiverAddress < Section

    def render
      float do
        bounding_box([290, 640], width: bounds.width, height: 80) do
          receiver_address_table
        end
      end
    end

    private

    def receiver_address_table
      if recipient
        receiver_address = receiver_address_data
      else
        return if recipient_address.blank?
        receiver_address = [recipient_address.split(/\n/)]
      end

      table(receiver_address, cell_style: { borders: [], padding: [0, 0, 0, 0] })
    end

    def receiver_address_data
      [
        [recipient.full_name],
        [recipient.address],
        ["#{recipient.zip_code} #{recipient.town}"],
        [Countries.label(recipient.country)]
      ]
    end
  end
end
