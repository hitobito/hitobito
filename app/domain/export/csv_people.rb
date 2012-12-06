require 'csv'
module Export
  module CsvPeople

    def self.export(people)
      Generator.new(People.new(people)).csv
    end

    def self.export_full(people)
      Generator.new(PeopleFull.new(people)).csv
    end


    # Generate using people class for headers and value mapping
    class Generator
      attr_reader :csv

      def initialize(people)
        @csv = CSV.generate(options) do |csv|
          csv << people.values
          people.list.each do |person|
            hash = Person.new(person)
            csv << people.keys.map { |key| hash[key] } 
          end
        end
      end

      def options
        { col_sep: Settings.csv.separator.strip }
      end
    end

    # Attributes of people we want to include 
    class People < Hash
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

      private
      def model_class
        ::Person
      end
      def attributes
        (model_class.column_names.map(&:to_sym) - [:id, :picture]) &
          [:first_name, :last_name, :nickname, :email, :address, :zip_code, :town, :country, :birthday]
      end

      def translate(attr)
        model_class.human_attribute_name(attr)
      end

      def add_associations
        merge!(labels(people.map(&:phone_numbers), Associations.phone_numbers))
      end

      def labels(collection, mapper) 
        collection.flatten.map(&:label).uniq.each_with_object({}) do |label, obj|
          obj[mapper.key(label)] = mapper.human(label)
        end
      end 
    end

    # adds social_accounts and company related attributes
    class PeopleFull < People
      def attributes
        super | (model_class::PUBLIC_ATTRS - [:id, :picture])
      end

      def add_associations
        super
        merge!(labels(people.map(&:social_accounts), Associations.social_accounts))
      end
    end

    # Attributes of a person, handles associations
    class Person < Hash
      def initialize(person)
        super()
        merge!(person.attributes.symbolize_keys)
        merge!(roles: map_roles(person.roles))
        person.phone_numbers.each { |number| merge!(map_object(number)) }
        person.social_accounts.each { |account| merge!(map_object(account)) }
      end

      private
      def map_object(object)
        case object
        when PhoneNumber then { Associations.phone_numbers.key(object.label) => object.value }
        when SocialAccount then { Associations.social_accounts.key(object.label) => object.name }
        end
      end

      def map_roles(roles)
        roles.map { |role| "#{role} #{role.group}"  }.join(', ')
      end
    end

    class Associations
      attr_reader :model

      class << self
        def phone_numbers
          @phone_numbers ||= self.new(PhoneNumber)
        end

        def social_accounts
          @social_accounts ||= self.new(SocialAccount)
        end
      end

      def initialize(model)
        @model = model
      end

      def key(label)
        "#{model.model_name.underscore}_#{label}".downcase.to_sym
      end

      def human(label)
        case model.model_name
        when "PhoneNumber" then "#{model.model_name.human} #{label.capitalize}"
        when "SocialAccount" then label.capitalize
        end
      end
    end


  end
end
