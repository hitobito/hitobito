# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::FullText
  
  attr_reader :person

  def self.load_accessible_deleted_people_ids(user)
    group = Group.find(user.primary_group_id)

    # TODO use Group::DeletedPeople.deleted_for after PR #64 is merged
    undeleted_roles = "SELECT * FROM roles " \
                      "WHERE roles.deleted_at IS NULL " \
                      "AND roles.person_id = people.id"

    subquery = "SELECT MAX(roles.deleted_at) FROM roles " \
                "WHERE roles.person_id = people.id " \
                "AND NOT EXISTS (#{undeleted_roles})"
    
    accessible_deleted = Person.joins('INNER JOIN roles ON roles.person_id = people.id').
                                where("roles.deleted_at = (#{subquery}) " \
                                      "AND (roles.group_id IN (?) OR roles.group_id = ?)",
                                group.layer_group.children.select(:id), group.id).
                                pluck(:id)
  end
end
