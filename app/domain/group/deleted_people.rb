# frozen_string_literal: true

#  Copyright (c) 2017-2026 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

class Group::DeletedPeople
  class << self
    def deleted_for(layer_group, person_joins = nil)
      people_in({layer_group_id: Array(layer_group).map(&:id)}, person_joins)
    end

    # Deleted people whose last roles were in groups matching the given conditions.
    def people_in(group_conditions, person_joins = nil)
      subquery = new(person_joins)
        .roles_of_deleted_people
        .joins(:group)
        .where(groups: group_conditions)
        .distinct
      Person.where(id: subquery.select(:person_id))
    end

    # People without active roles whose last non-restricted role was in one of the given groups.
    def last_non_restricted_role_in(groups)
      restricted = Role.all_types.select(&:restricted?).map(&:sti_name)
      last_roles = Role.with_inactive
        .where.not(type: restricted)
        .where.not(person_id: Role.select(:person_id))
        .select("DISTINCT ON (roles.person_id) roles.person_id, roles.group_id")
        .order(:person_id, end_on: :desc)
      last_roles_in_groups = Role.unscoped.from(last_roles, :roles).where(group_id: groups)
      Person.where(id: last_roles_in_groups.select(:person_id))
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
