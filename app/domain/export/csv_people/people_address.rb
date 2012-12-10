module Export::CsvPeople
  # Attributes of people we want to include
  class PeopleAddress < Hash
    attr_reader :people

    def initialize(people)
      super()
      @people = people

      attributes.each { |attr| merge!(attr => translate(attr)) }
      merge!(roles: 'Rollen')
      add_associations
    end

    def list
      people
    end

    def create(person)
      Export::CsvPeople::Person.new(person)
    end

    private
    
    def model_class
      ::Person
    end
    
    def attributes
      [:first_name, :last_name, :nickname, :company_name, :company, :email, 
       :address, :zip_code, :town, :country, :birthday]
    end

    def translate(attr)
      model_class.human_attribute_name(attr)
    end

    def add_associations
      merge!(labels(people.map(&:phone_numbers), Accounts.phone_numbers))
    end

    def labels(collection, mapper)
      collection.flatten.map(&:label).uniq.each_with_object({}) do |label, obj|
        obj[mapper.key(label)] = mapper.human(label)
      end
    end
  end
end