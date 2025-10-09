#  Copyright (c) 2012-2017, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class Event::ParticipationContactDataAbility < AbilityDsl::Base
  on(Event::ParticipationContactData) do
    permission(:any).may(:show, :update).her_own

    for_self_or_manageds do
      # abilities which managers inherit from their managed children
      permission(:any).may(:show, :update).her_own
    end
  end

  def her_own
    subject.person.id == user.id
  end
end
