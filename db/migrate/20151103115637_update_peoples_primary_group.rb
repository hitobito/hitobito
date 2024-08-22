#  Copyright (c) 2015, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class UpdatePeoplesPrimaryGroup < ActiveRecord::Migration[4.2]
  def up
    # TODO: does not work anymore with current code base.
    # Using activerecord in migration is bad practice.
    # Solve with plain sql or in a rake task or in a job that can be scheduled.

    # # people with no primary group and only one active role
    # people = Person.joins(:roles).where(primary_group_id: nil).group('people.id').having('count(distinct roles.group_id) = 1')
    # people.find_each do |p|
    #   group_id = p.roles.first.group_id
    #   p.update_column(:primary_group_id, group_id)
    # end
  end
end
