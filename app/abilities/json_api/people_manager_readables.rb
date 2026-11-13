# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module JsonApi
  class PeopleManagerReadables
    include CanCan::Ability

    def initialize(user)
      return unless FeatureGate.enabled?("people.people_managers.api")

      can :read, PeopleManager, managed: readable_people(user)
    end

    private

    def readable_people(user)
      Person.accessible_by(PersonReadables.new(user)).unscope(:select)
    end
  end
end
