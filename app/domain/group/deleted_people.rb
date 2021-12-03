# frozen_string_literal: true

#  Copyright (c) 2017 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

class Group::DeletedPeople

  class << self

    def deleted_for(layer_group)
      Person.
        joins('INNER JOIN roles ON roles.person_id = people.id').
        joins("INNER JOIN #{Group.quoted_table_name} " \
              "ON #{Group.quoted_table_name}.id = roles.group_id").
        where(undeleted_roles.arel.exists.not).
        where('roles.deleted_at = (?)', last_role_deleted).
        where("#{Group.quoted_table_name}.layer_group_id = ?", layer_group.id).
        distinct
    end

    private

    def undeleted_roles
      Role.without_deleted
          .where('roles.person_id = people.id')
    end

    def last_role_deleted
      Role.with_deleted
          .where('roles.person_id = people.id')
          .select('MAX(roles.deleted_at)')
    end

  end

end
