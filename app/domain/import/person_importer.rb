# encoding: UTF-8
module Import
  class PersonImporter
    attr_accessor :data, :role_type, :group, :errors, :doublettes,
      :failure_count, :success_count, :doublette_count


    def initialize(hash={})
      @errors = []
      @failure_count = 0
      @success_count = 0
      @doublette_count = 0
      @doublettes = []

      hash.each { |key, value| self.send("#{key}=", value) } 
    end

    def import
      data.each_with_index do |hash,index| 
        import_person(hash,index)
      end
      errors.present?
    end

    def import_person(hash,index)
      person = Import::Person.new(hash)
      doublette = person.persisted?

      person.add_role(group, role_type)
      if person.errors.empty? && person.save
        if doublette 
          if !doublettes.include?(person.id)
            @doublette_count += 1 
            @doublettes << person.id
          end
        else person.persisted?
          @success_count += 1
        end
        true
      else
        @failure_count += 1
        errors << "Zeile #{index + 1}: #{person.human_errors}"
        false
      end
    end

    def human_name(args={})
      "#{::Person.model_name.human(args)}(#{human_role_name})"
    end

    def human_role_name
      @role_name ||= @role_type.constantize.model_name.human
    end

  end
end
