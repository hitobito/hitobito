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
    Person.where(household_key: nil, id: @people)
  end

  def household_people
    Person.where.not(household_key: nil).where(id: @people)
  end

end
