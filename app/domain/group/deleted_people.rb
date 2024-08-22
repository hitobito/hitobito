# frozen_string_literal: true

#  Copyright (c) 2017-2023 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

class Group::DeletedPeople
  class << self
    def deleted_for_multiple(layer_groups)
      Person
        .joins("INNER JOIN roles ON roles.person_id = people.id")
        .joins("INNER JOIN #{Group.quoted_table_name} " \
              "ON #{Group.quoted_table_name}.id = roles.group_id")
        .where(no_active_roles_exist)
        .where("roles.end_on = (?)", lastest_role_ended_on)
        .where("#{Group.quoted_table_name}.layer_group_id IN (?)", layer_groups.map(&:id))
        .distinct
    end

    def deleted_for(layer_group)
      Person
        .joins("INNER JOIN roles ON roles.person_id = people.id")
        .joins("INNER JOIN #{Group.quoted_table_name} " \
              "ON #{Group.quoted_table_name}.id = roles.group_id")
        .where(no_active_roles_exist)
        .where("roles.end_on = (?)", lastest_role_ended_on)
        .where("#{Group.quoted_table_name}.layer_group_id = ?", layer_group.id)
        .distinct
    end

    def group_for_deleted(person)
      Group.joins("INNER JOIN roles ON roles.group_id = groups.id")
        .joins("INNER JOIN #{Person.quoted_table_name} " \
                  "ON #{Person.quoted_table_name}.id = roles.person_id")
        .where(no_active_roles_exist)
        .where("roles.end_on = (?)", lastest_role_ended_on)
        .find_by("#{Person.quoted_table_name}.id = ?", person.id)
    end

    private

    def no_active_roles_exist
      active_roles.arel.exists.not
    end

    def active_roles
      Role.active
        .where("roles.person_id = people.id")
    end

    def lastest_role_ended_on
      Role.ended
        .where("roles.person_id = people.id")
        .select("MAX(roles.end_on)")
    end
  end
end
