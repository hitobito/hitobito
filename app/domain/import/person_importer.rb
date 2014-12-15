# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Import
  class PersonImporter
    include Translatable

    attr_reader :data, :role_type, :group, :override,
                :failure_count, :new_count, :errors


    def initialize(data, group, role_type, override = false)
      @data = data
      @group = group
      @role_type = role_type
      @override = override
      @imported_emails = {}
      @failure_count = 0
      @new_count = 0
      @errors = []
    end

    def import
      save_results = people.map { |p| valid?(p) && p.save }
      !save_results.include?(false)
    end

    def people
      @people ||= populate_people
    end

    def human_name(args = {})
      "#{::Person.model_name.human(args)} (#{human_role_name})"
    end

    def human_role_name
      @role_type.label
    end

    def doublette_count
      doublette_finder.doublette_count
    end

    private

    def populate_people
      data.each_with_index.map do |attributes, index|
        populate_person(attributes.with_indifferent_access, index)
      end
    end

    def populate_person(attributes, index)
      person = doublette_finder.find(attributes) || ::Person.new

      import_person = Import::Person.new(person, attributes, override)
      import_person.populate
      import_person.add_role(group, role_type)

      count_person(import_person, index)
      import_person
    end

    def count_person(import_person, index)
      if valid?(import_person)
        @new_count += 1 if import_person.new_record?
      else
        @failure_count += 1
        @errors << translate(:row_with_error, row: index + 1, errors: import_person.human_errors)
      end
    end

    def valid?(import_person)
      import_person.valid? && import_person.email_unique?(@imported_emails)
    end

    def doublette_finder
      @doublette_finder ||= PersonDoubletteFinder.new
    end

  end
end
