# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class EventAbility
    include CanCan::Ability

    def initialize(main_ability)
      return unless main_ability.can?(:list_available, ::Event)

      can :read, ::Event
      can :read, ::Event::Course
      can :read, ::Event::Kind
      can :read, ::Event::KindCategory
    end
  end
end
