# encoding: utf-8

#  Copyright (c) 2015, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class UpdatePeoplesPrimaryGroup < ActiveRecord::Migration[4.2]
  def up
    # people with no primary group and only one active role
    people = Person.joins(:roles).where(primary_group_id: nil).group('people.id').having('count(distinct roles.group_id) = 1')
    people.find_each do |p|
      group_id = p.roles.first.group_id
      p.update_column(:primary_group_id, group_id)
    end
  end
end
