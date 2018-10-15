# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Import
  class PersonImporter
    include Translatable

    attr_reader :data, :role_type, :group, :options,
                :failure_count, :new_count, :request_people, :errors

    attr_accessor :user_ability

    def initialize(data, group, role_type, options = {})
      @data = data
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
      save_results = people.each_with_index.map { |p, i| valid?(p) && save_person(p, i) }
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

    def update_count
      doublette_finder.doublette_count - request_people.size
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
      data.each_with_index.map do |attributes, index|
        populate_person(attributes.with_indifferent_access, index)
      end
    end

    def populate_person(attributes, index)
      person = doublette_finder.find(attributes) || ::Person.new
      attributes.delete(:email) if illegal_email_update?(person)

      import_person = Import::Person.new(person, attributes, options)
      import_person.populate
      import_person.add_role(group, role_type)

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

    def doublette_finder
      @doublette_finder ||= PersonDoubletteFinder.new
    end

  end
end
