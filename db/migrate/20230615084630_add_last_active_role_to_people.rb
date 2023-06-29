# frozen_string_literal: true

#  Copyright (c) 2023, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddLastActiveRoleToPeople < ActiveRecord::Migration[6.1]
  def up
    add_column :people, :last_active_role_id, :integer, null: true

    say_with_time('assigning last_active_role') do
      people_without_active_roles.find_each do |person|
        person.update_column(:last_active_role_id,
                             person.roles
                                   .unscope(where: :'roles.deleted_at')
                                   .where.not(roles: { deleted_at: nil })
                                   .where(roles: { deleted_at: ..Time.now.utc })
                                   .order(deleted_at: :desc).first.id)
      end
    end
  end

  def down
    remove_column :people, :last_active_role_id
  end

  def people_without_active_roles
    Person.joins('INNER JOIN roles ON roles.person_id = people.id')
          .where(no_active_roles_exist)
          .distinct
  end

  def no_active_roles_exist
    active_roles.arel.exists.not
  end

  def active_roles
    Role.unscope(where: :'roles.deleted_at')
        .where(roles: { deleted_at: nil })
        .or(Role.unscoped.where(Role.arel_table[:deleted_at].gt(Time.now.utc)))
        .where('roles.person_id = people.id')
  end
end
