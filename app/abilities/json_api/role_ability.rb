# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class RoleAbility
    include CanCan::Ability

    def initialize(main_ability, api_scopes: ["api"])
      return if !(api_scopes.include?("groups") || api_scopes.include?("people")) &&
        !api_scopes.include?("api")
      can :read, Role, person: full_readable_people(main_ability)
    end

    private

    def full_readable_people(main_ability)
      Person.accessible_by(PersonFullReadables.new(main_ability.user))
        .unscope(:select)
    end
  end
end
