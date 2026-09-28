# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Import
  class PersonImporter
    include Translatable

    attr_reader :data, :role_type, :group, :options,
      :failure_count, :new_count, :request_people, :errors

    attr_accessor :user_ability

    def initialize(data, group, role_type, options = {})
      @data = data.map(&:with_indifferent_access)
      @group = group
      @role_type = role_type
      @options = options
      @imported_emails = {}
      @failure_count = 0
      @new_count = 0
      @request_people = []
      @errors = []
    end

    def import
      return false if id_mapped? && !ids_valid?

      save_results = people.each_with_index.map { |p, i| valid?(p) && save_person(p, i) }
      ::Person.connection.reset_pk_sequence!("people") if id_mapped?
      !save_results.include?(false)
    end

    def people
      @people ||= populate_people
    end

    def id_mapped?
      data.first&.key?(:id) || false
    end

    def human_name(args = {})
      "#{::Person.model_name.human(args)} (#{human_role_name})"
    end

    def human_role_name
      @role_type.label
    end

    def update_count
      existing_count - request_people.size
    end

    private

    def save_person(import_person, _index)
      creator = request_creator(import_person)

      if creator && creator.required?
        creator.create_request
      else
        import_person.save
      end
    end

    def populate_people
      return [] unless ids_valid?

      data.each_with_index.map do |attributes, index|
        person_attrs = attributes.except(*Import::Person::ROLE_ATTRIBUTES)
        role_attrs = attributes.slice(*Import::Person::ROLE_ATTRIBUTES)

        populate_person(index, person_attrs, role_attrs.compact_blank)
      end
    end

    def populate_person(index, person_attrs, role_attrs)
      person = find_person(person_attrs) || ::Person.new
      person_attrs.delete(:email) if illegal_email_update?(person)

      import_person = Import::Person.new(person, person_attrs, options)
      import_person.populate
      import_person.add_role(group, role_type, role_attrs)

      count_person(import_person, index)
      import_person
    end

    def illegal_email_update?(person)
      person.persisted? && !user_ability.can?(:update_email, person)
    end

    def valid?(import_person)
      import_person.valid? && import_person.email_unique?(@imported_emails)
    end

    def count_person(import_person, index)
      if valid?(import_person)
        count_valid_person(import_person)
      else
        @failure_count += 1
        @errors << translate(:row_with_error, row: index + 1, errors: import_person.human_errors)
      end
    end

    def count_valid_person(import_person)
      creator = request_creator(import_person)
      if import_person.new_record?
        @new_count += 1
      elsif creator && creator.required?
        @request_people << import_person.person
      end
    end

    def request_creator(import_person)
      user_ability && import_person.persisted? && import_person.role &&
        ::Person::AddRequest::Creator::Group.new(import_person.role, user_ability)
    end

    def find_person(attrs)
      return duplicate_finder.find(attrs) unless id_mapped?

      ::Person.find_by(id: attrs[:id]).tap do |person|
        existing_ids[person.id] = person if person
      end
    end

    def existing_ids
      @existing_ids ||= {}
    end

    def existing_count
      id_mapped? ? existing_ids.size : duplicate_finder.unique_count
    end

    # Pre-validation when id is mapped: every row needs an id value and all
    # ids must be unique. Violations abort the whole import.
    def ids_valid?
      return true unless id_mapped?

      @errors |= id_errors
      id_errors.empty?
    end

    def id_errors
      @id_errors ||= validate_ids
    end

    def validate_ids
      [missing_ids_error, duplicate_ids_error].compact
    end

    def missing_ids_error
      rows = data.each_with_index.filter_map { |row, index| index + 1 if row[:id].blank? }
      translate(:missing_ids, rows: rows.join(", ")) if rows.any?
    end

    def duplicate_ids_error
      ids = data.filter_map { |row| row[:id].presence }
        .tally
        .filter_map { |id, count| id if count > 1 }
      translate(:duplicate_ids, ids: ids.join(", ")) if ids.any?
    end

    def duplicate_finder
      @duplicate_finder ||= PersonDuplicateFinder.new
    end

    # After importing people with explicit ids, the pk sequence must be
    # ahead of max(id), so subsequent inserts get free ids.
    def reset_pk_sequence
      connection = ::Person.connection
      sequence = connection.select_value(
        "SELECT pg_get_serial_sequence('people', 'id')"
      )
      return unless sequence

      last_value = connection.select_value("SELECT last_value FROM #{sequence}").to_i
      connection.reset_pk_sequence!("people") if last_value < ::Person.maximum(:id).to_i
    end
  end
end
