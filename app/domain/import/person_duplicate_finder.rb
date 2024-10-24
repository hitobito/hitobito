# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Import
  class PersonDuplicateFinder
    include Translatable

    # if multiple rows match the same existing person, always return the same object
    attr_reader :unique_entries

    def initialize
      @unique_entries = {}
    end

    def unique_count
      unique_entries.size
    end

    # returns the first duplicate with errors if there are multiple
    def find(attrs)
      result = duplicate_ids_with_first_person(attrs)
      people_ids = result[:people_ids]
      return if people_ids.blank?

      person = result[:first_person]
      handle_duplicate(person, people_ids)
    end

    private

    def find_first_person(people_ids)
      ::Person.find(people_ids.first) if people_ids.present?
    end

    def handle_duplicate(person, people_ids)
      if people_ids.size == 1
        # set new unique entry or use and return existing entry
        unique_entries[person.id] ||= person
      else
        person.errors.add(:base, translate(:duplicates, count: people_ids.size))
        person
      end
    end

    def duplicate_ids_with_first_person(attrs)
      conditions = People::DuplicateConditions.new(attrs).build
      if conditions.first.present?
        people_ids = ::Person.where(conditions).pluck(:id)
        {people_ids:, first_person: find_first_person(people_ids)}
      else
        {people_ids: [], first_person: nil}
      end
    end
  end
end
