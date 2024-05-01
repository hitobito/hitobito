# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class GroupAbility
    include CanCan::Ability

    def initialize(main_ability)
      can :read, Group if main_ability.user&.roles&.present? || main_ability.user&.root?
    end
  end
end
