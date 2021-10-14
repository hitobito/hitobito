# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::HouseholdList

  def initialize(people)
    @people = people
  end

  def people_without_household
    @people.unscope(:select).where(household_key: nil)
  end

  def grouped_households
    people = Person.quoted_table_name
    # group by household, keep NULLs separate
    group_by = "IFNULL(#{people}.`household_key`, #{people}.`id`)"

    # remove previously added selects, very important to make this query scale
    @people.unscope(:select).
        select("(#{group_by}) as `key`, MIN(#{people}.`id`) as `id`").
        group(group_by)
  end

  def only_households
    grouped_households.where.not(household_key: nil)
  end

end
