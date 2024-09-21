# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::NameResource < ApplicationResource
  self.model = ::Person
  self.type = "person-name"

  with_options writable: false, filterable: false, sortable: false do
    attribute :first_name, :string
    attribute :last_name, :string
  end

  # Custom filter allowing to include people with specific roles as custom association on course
  filter :leads_course_id, :integer, only: :eq do
    eq do |scope, course_ids|
      scope
        .joins(event_participations: :roles)
        .select("people.id, first_name, last_name, event_id AS leads_course_id")
        .where(event_participations: {event_id: course_ids},
          event_roles: {type: Event::Course::LEADER_ROLES})
    end
  end

  def base_scope
    Person.only_public_data.order_by_name.accessible_by(index_ability)
  end

  def index_ability
    PersonReadables.new(current_ability.user)
  end
end
