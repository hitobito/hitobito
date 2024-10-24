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
      duplicate_id = find_duplicate_id(person)

      next unless duplicate_id

      # Sorting by id to only allow a single PersonDuplicate entry per Person combination
      person_1, person_2 = [person.id, duplicate_id].sort

      PersonDuplicate.find_or_create_by!(person_1_id: person_1, person_2_id: person_2)
    end
  end

  private

  def find_duplicate_id(person)
    conditions =
      Import::PersonDuplicate::Attributes.new(person.attributes)
        .duplicate_conditions
    duplicate_ids = find_people_ids(conditions)

    duplicate_ids.first unless person.id == duplicate_ids.first
  end

  # returns the first duplicate with errors if there are multiple
  def find_people_ids(conditions)
    if conditions.first.present?
      ::Person.where(conditions).pluck(:id)
    else
      []
    end
  end
end
