# encoding: UTF-8
module Import
  class PersonImporter
    attr_accessor :data, :role_type, :group, :errors, :doublettes,
                  :failure_count, :new_count, :doublette_count


    def initialize(hash={})
      @errors = []
      @failure_count = 0
      @new_count = 0
      @doublettes = {}
      hash.each { |key, value| self.send("#{key}=", value) }
    end

    def people
      @people ||= data.each_with_index.map { |hash,index|  populate_people(hash,index) }
    end

    def import
      save_results = people.map(&:save)
      save_results.all? { |result| result }
    end

    def human_name(args={})
      "#{::Person.model_name.human(args)} (#{human_role_name})"
    end

    def human_role_name
      @role_name ||= @role_type.constantize.label
    end

    def doublette_count
      doublettes.keys.count
    end

    private
    def populate_people(hash,index)
      person = Import::Person.new(hash, unique_emails)
      person.add_role(group, role_type)

      # DoubletteFinder in Person populates errors, still check if initialized person is valid
      if person.errors.empty? && valid?(person)
        if person.persisted?
          handle_persisted(person)
          person = doublettes[person.id]
        else
          @new_count += 1
        end
      else
        @failure_count += 1
        errors << "Zeile #{index + 1}: #{person.human_errors}"
      end
      person
    end

    def handle_persisted(import_person)
      if !doublettes.has_key?(import_person.id)
        doublettes[import_person.id] = import_person
      else
        consolidate_doublette(import_person)
      end
    end

    def consolidate_doublette(import_person)
      unified_import_person = doublettes[import_person.id]
      person = unified_import_person.person

      blank_attrs = import_person.hash.select {|key, value| person.attributes[key].blank? }
      person.attributes = blank_attrs

      person.phone_numbers << import_person.person.phone_numbers
      person.social_accounts << import_person.person.social_accounts
    end

    # we ignore duplicate emails for persisted people, they are handle by doublettes
    def valid?(person)
      (person.persisted? && person.person.valid?) || person.valid?
    end

    # used by Import::Person to check if emails are unique
    def unique_emails
      @unique_emails ||= Set.new
    end

  end
end
