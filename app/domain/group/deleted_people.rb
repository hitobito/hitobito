# encoding: utf-8

#  Copyright (c) 2014 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

class Group::DeletedPeople

  def self.deleted_for(group)

    undeleted_roles = "SELECT * FROM roles " \
                        "WHERE roles.deleted_at IS NULL " \
                        "AND roles.person_id = people.id"

    subquery = "SELECT MAX(roles.deleted_at) FROM roles " \
                 "WHERE roles.person_id = people.id " \
                 "AND NOT EXISTS (#{undeleted_roles})"
    Person.
      joins('INNER JOIN roles ON roles.person_id = people.id').
      where("roles.deleted_at = (#{subquery}) AND (roles.group_id IN (?) OR roles.group_id = ?)",
        group.layer_group.children.select(:id), group.id)
  end

end
