# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::AddressRenderers
  def address_position(group)
    x_coords = {
      left: self.class::LEFT_ADDRESS_X,
      right: self.class::RIGHT_ADDRESS_X
    }[group.settings(:messages_letter).address_position&.to_sym]
    x_coords ||= 0
    [x_coords, cursor]
  end
end
