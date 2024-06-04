#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module HouseholdHelper

  def household_member_ids_without(member)
    entry.people.excluding(member.person).map(&:id)
  end

  def household_member_row_class(member)
    unless member.valid?
      member.errors.any? ? 'table-danger' : 'table-warning'
    end
  end
end
