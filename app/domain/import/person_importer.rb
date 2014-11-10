# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Import
  class PersonImporter
    include Translatable

    attr_reader :data, :role_type, :group, :errors, :doublettes,
                :failure_count, :new_count, :doublette_count


    def initialize(data, group, role_type)
      @data = data
      @group = group
      @role_type = role_type
      @errors = []
      @failure_count = 0
      @new_count = 0
      @doublettes = {}
    end

    def people
      @people ||= populate_people
    end

    def import
      save_results = people.map { |p| valid?(p) && p.save }
      !save_results.include?(false)
    end

    def human_name(args = {})
      "#{::Person.model_name.human(args)} (#{human_role_name})"
    end

    def human_role_name
      @role_name ||= @role_type.label
    end

    def doublette_count
      doublettes.keys.count
    end

    private

    def populate_people
      data.each_with_index.map { |attributes, index| populate_person(attributes, index) }
    end

    def populate_person(attributes, index)
      person = Import::Person.new(attributes, unique_emails)
      person.add_role(group, role_type)

      validate_person(person, index) do
        handle_imported_person(person)
      end
    end

    def validate_person(person, index)
      if valid?(person)
        yield
      else
        @failure_count += 1
        errors << translate(:row_with_error, row: index + 1, errors: person.human_errors)
        person
      end
    end

    def handle_imported_person(person)
      if person.persisted?
        handle_potential_dublette(person)
        doublettes[person.id]
      else
        @new_count += 1
        person
      end
    end

    def handle_potential_dublette(import_person)
      if !doublettes.key?(import_person.id)
        doublettes[import_person.id] = import_person
      else
        consolidate_doublette(import_person)
      end
    end

    def consolidate_doublette(import_person)
      unified_import_person = doublettes[import_person.id]
      person = unified_import_person.person

      blank_attrs = import_person.attributes.select { |key, _value| person.attributes[key].blank? }
      person.attributes = blank_attrs

      person.phone_numbers << import_person.person.phone_numbers
      person.social_accounts << import_person.person.social_accounts
    end

    # we ignore duplicate emails for persisted people, they are handle by doublettes
    def valid?(person)
      # DoubletteFinder in Person populates errors,
      # still check if initialized person is valid
      person.errors.empty? &&
      ((person.persisted? && person.person.valid?) ||
       person.valid?)
    end

    # used by Import::Person to check if emails are unique
    def unique_emails
      @unique_emails ||= {}
    end

  end
end
