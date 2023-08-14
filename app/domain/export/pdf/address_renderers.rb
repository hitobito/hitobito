# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::AddressRenderers
  extend ActiveSupport::Concern

  included do
    class_attribute :left_address_x, default: 0
    class_attribute :right_address_x, default: 290
  end

  def address_position(group)
    x_coords = {
      left: left_address_x,
      right: right_address_x
    }[group.letter_address_position&.to_sym]
    x_coords ||= 0
    [x_coords, cursor]
  end
end
