#  Copyright (c) 2012-2017, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class Event::ParticipationContactDataAbility < AbilityDsl::Base
  on(Event::ParticipationContactData) do
    permission(:any).may(:show, :update).her_own
  end

  def her_own
    subject.person.id == user.id
  end
end
