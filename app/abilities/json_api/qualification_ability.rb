# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class QualificationAbility
    include CanCan::Ability

    def initialize(user)
      can :read, Qualification, person: full_readable_people(user)
    end

    private

    def full_readable_people(user)
      Person
        .accessible_by(PersonFullReadables.new(user))
        .unscope(:select)
    end
  end
end
