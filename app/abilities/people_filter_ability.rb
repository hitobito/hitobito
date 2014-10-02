# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeopleFilterAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(::PeopleFilter) do
    permission(:contact_data).may(:new).all
    permission(:group_read).may(:new).in_same_group
    permission(:layer_read).may(:new).in_same_layer
    permission(:layer_full).may(:create, :destroy).in_same_layer
    permission(:layer_and_below_read).may(:new).in_same_layer_or_below
    permission(:layer_and_below_full).may(:create, :destroy).in_same_layer
  end

end
