# encoding: utf-8

#  Copyright (c) 2014 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

class Group::DeletedPeople

  def self.deleted_for(group)
    subquery = "select max(roles.deleted_at) from roles " \
               "where roles.person_id = people.id and people.primary_group_id is null"
    query =    "select people.* from people inner join roles on roles.person_id = people.id " \
               "where roles.deleted_at = (#{subquery}) and roles.group_id = ?;"
    Person.find_by_sql([query, group.id])
  end

end
