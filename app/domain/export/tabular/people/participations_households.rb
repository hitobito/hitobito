#  Copyright (c) 2018-2018, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class ParticipationsHouseholds < Households
    def initialize(list)
      super(people(list))
    end

    def people(list)
      list.map(&:person)
    end
  end
end
