# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class People::DuplicateLocator
  def initialize(scope = Person.all)
    @scope = scope
  end

  def run
    @scope.find_each do |person|
      duplicate = find_duplicate(person)

      next unless duplicate

      # Sorting by id to only allow a single PersonDuplicate entry per Person combination
      person_1, person_2 = [person, duplicate].sort_by(&:id)

      PersonDuplicate.find_or_create_by!(person_1: person_1, person_2: person_2)
    end
  end

  private

  def find_duplicate(person)
    duplicate = person_duplicate_finder.find({first_name: person.first_name,
                                              last_name: person.last_name,
                                              company_name: person.company_name,
                                              zip_code: person.zip_code,
                                              birthday: person.birthday})

    duplicate unless person == duplicate
  end

  def person_duplicate_finder
    @person_duplicate_finder ||= Import::PersonDuplicateFinder.new
  end
end
