#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ApplicationAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Event
  include AbilityDsl::Constraints::Event::Participation

  on(Event::Application) do
    permission(:any).may(:show_priorities, :show_approval).her_own

    permission(:group_full).may(:show_priorities, :show_approval).in_same_group
    permission(:group_and_below_full).may(:show_priorities, :show_approval).in_same_group_or_below
    permission(:layer_full).may(:show_priorities, :show_approval).in_same_layer_or_different_prio
    permission(:layer_and_below_full)
      .may(:show_priorities, :show_approval)
      .in_same_layer_or_different_prio

    permission(:approve_applications)
      .may(:show_priorities, :show_approval, :approve, :reject)
      .for_applicant_in_same_layer
  end
end
