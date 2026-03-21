#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PassAbility < AbilityDsl::Base
  on(Pass) do
    permission(:any).may(:show).herself
  end

  def person
    subject.person
  end

  def herself
    subject.person_id == user.id
  end
end
