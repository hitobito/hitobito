# frozen_string_literal: true

#  Copyright (c) 2023, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Roles::AssignLastActiveRoleJob < RecurringJob

  run_every 1.day

  attr_reader :logs

  def initialize
    super
    @logs = Hash.new { |hash, key| hash[key] = [] }
  end

  def perform_internal
    new_people_without_active_roles.find_each do |person|
      person.update_column(:last_active_role_id,
                           person.roles.only_deleted.order(deleted_at: :desc).first.id)
    end

    people_to_unassign_last_active_role.find_each do |person|
      person.update_column(:last_active_role_id, nil)
    end
  end

  def people_to_unassign_last_active_role
    Person.joins('INNER JOIN roles ON roles.person_id = people.id')
          .where('people.last_active_role_id IS NOT NULL')
          .where(active_roles.arel.exists)
          .distinct
  end

  def new_people_without_active_roles
    Person.joins('INNER JOIN roles ON roles.person_id = people.id')
          .where('people.last_active_role_id IS NULL')
          .where(no_active_roles_exist)
          .distinct
  end

  def no_active_roles_exist
    active_roles.arel.exists.not
  end

  def active_roles
    Role.without_deleted
        .where('roles.person_id = people.id')
  end

  def last_role_deleted_at
    Role.only_deleted
        .where('roles.person_id = people.id')
        .select('MAX(roles.deleted_at)')
  end
end
