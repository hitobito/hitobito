# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CalendarAbility < AbilityDsl::Base

  on(Calendar) do
    permission(:layer_full).may(:manage).in_same_layer
    permission(:layer_and_below_full).may(:manage).in_same_layer
  end

  def in_same_layer
    user.groups.map(&:layer_group_id).include? subject.group.layer_group.id
  end

end
