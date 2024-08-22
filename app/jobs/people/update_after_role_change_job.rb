# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class People::UpdateAfterRoleChangeJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    update_contact_data_visible_flag
    update_missing_primary_group_ids
    update_invalid_primary_group_ids
  end

  def update_contact_data_visible_flag
    contact_data_role_types = Role.all_types.select { |rt| rt.permissions.include?(:contact_data) }
    contact_data_visible = Role.where(type: contact_data_role_types).select(:person_id)
    people.where("id IN (?)", contact_data_visible).update_all(contact_data_visible: true)  # rubocop:disable Rails/WhereEquals
    people.where("NOT id IN (?)", contact_data_visible).update_all(contact_data_visible: false)
  end

  def update_missing_primary_group_ids
    people.joins(:roles).includes(:roles).where(primary_group_id: nil).find_each do |person|
      People::UpdateAfterRoleChange.new(person).set_first_primary_group
    end
  end

  def update_invalid_primary_group_ids
    active_primary_group_roles = <<~SQL
      LEFT JOIN roles ON (
        roles.person_id = people.id AND roles.group_id = people.primary_group_id
        AND #{arel_table(:start_on).lteq(Time.zone.today).or(arel_table(:start_on).eq(nil)).to_sql}
        AND #{arel_table(:end_on).gteq(Time.zone.today).or(arel_table(:end_on).eq(nil)).to_sql}
      )
    SQL

    scope = people.joins(active_primary_group_roles).where(roles: {id: nil})
    scope.where.not(primary_group_id: nil).find_each do |person|
      People::UpdateAfterRoleChange.new(person).set_first_primary_group
    end
  end

  def arel_table(key)
    Role.arel_table[key]
  end

  def people
    Person.where.not(id: Person.root.id)
  end

  def next_run
    interval.from_now.midnight + 1.minute
  end
end
