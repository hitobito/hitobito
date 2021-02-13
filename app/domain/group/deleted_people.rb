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
        joins("INNER JOIN roles ON roles.person_id = people.id").
        joins("INNER JOIN #{Group.quoted_table_name} " \
              "ON #{Group.quoted_table_name}.id = roles.group_id").
        where("NOT EXISTS (#{undeleted_roles})").
        where("roles.deleted_at = (#{last_role_deleted})").
        where("#{Group.quoted_table_name}.layer_group_id = ?", layer_group.id).
        distinct
    end

    private

    def undeleted_roles
      "SELECT * FROM roles " \
      "WHERE roles.deleted_at IS NULL " \
      "AND roles.person_id = people.id"
    end

    def last_role_deleted
      "SELECT MAX(roles.deleted_at) FROM roles " \
      "WHERE roles.person_id = people.id "
    end

  end

end
