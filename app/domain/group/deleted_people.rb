# frozen_string_literal: true

#  Copyright (c) 2017-2023 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

class Group::DeletedPeople
  class << self
    def deleted_for(layer_group, person_joins = nil)
      subquery = new(person_joins)
        .roles_of_deleted_people
        .joins(:group)
        .where(groups: {layer_group_id: Array(layer_group).map(&:id)})
        .distinct
      Person.where(id: subquery.select(:person_id))
    end

    def group_for_deleted(person)
      Group.where(id: new.roles_of_deleted_people.where(person_id: person.id).select(:group_id))
        .first
    end
  end

  def initialize(person_joins = nil)
    @person_joins = person_joins
  end

  def roles_of_deleted_people
    Role
      .with_inactive
      .with(last_roles:, active_roles:)
      .joins("INNER JOIN last_roles ON last_roles.person_id = roles.person_id " \
        "AND last_roles.max_end_on = roles.end_on")
      .joins("LEFT JOIN active_roles ON active_roles.person_id = roles.person_id")
      .where(active_roles: {person_id: nil})
  end

  def last_roles
    Role
      .with_inactive
      .where(end_on: ...Date.current)
      .group("roles.person_id")
      .select("roles.person_id, MAX(end_on) AS max_end_on")
      .then { with_person_joins(_1) }
  end

  def active_roles
    Role.active.select(:person_id).distinct.then { with_person_joins(_1) }
  end

  # limiting the scope to only people that have entries on a given join table
  # drastically improves performance
  def with_person_joins(scope)
    if @person_joins
      scope.joins(person: @person_joins)
    else
      scope
    end
  end
end
