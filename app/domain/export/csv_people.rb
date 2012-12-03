require 'csv'
module Export
  module CsvPeople


    def self.export(people)
      Generator.new(people, Simple).csv
    end

    def self.export_full(people)
      Generator.new(people, Full).csv
    end


    class Generator
      attr_reader :csv

      def initialize(people, exporter_class)
        exported = people.map {|person| exporter_class.new(person) } 
        @csv = CSV.generate(options) do |csv|
          csv << exporter_class.translated_headers
          exported.each do |person|
            csv << person.values
          end
        end
      end

      def options
        { col_sep: Settings.csv.separator.strip }
      end
    end

    class Simple
      attr_reader  :person, :hash

      class << self
        def headers
          attributes + associations
        end

        def associations
          [:roles] + settings_phone_numbers.keys.map(&:to_sym) 
        end

        def attributes
          [:first_name, :last_name, :nickname, :email, :address, :zip_code, :town, :country, :birthday]
        end

        def settings_phone_numbers
          @settings_phone_numbers ||= Import::SettingsFields.new(PhoneNumber)
        end

        def translated_headers
          attributes.map { |attr| Person.human_attribute_name(attr) } + 
            [Role.model_name.human(count: 2)] + 
            settings_phone_numbers.values
        end
      end

      def initialize(person)
        @person = person
        @hash = core_attributes
        add_roles
        add_phone_numbers
      end

      def person_phone_numbers
        person.phone_numbers.public
      end

      def values
        self.class.headers.map { |header| hash[header] } 
      end

      private
      def core_attributes
        attributes = person.attributes.symbolize_keys!
        attributes.select! {|key| self.class.attributes.include?(key) } 
      end

      def add_roles
        roles = person.roles.map do |role| 
          "#{role} #{role.group}" 
        end
        hash[:roles] = roles.join(', ')
      end

      def add_phone_numbers
        fields = self.class.settings_phone_numbers
        person_phone_numbers.each do |number|
          hash[fields.key_for(number.label).to_sym] = number.value
        end
      end

    end

    class Full < Simple
      class << self
        def attributes
          super | Import::Person.person_attributes.map { |entry| entry[:key].to_sym }
        end

        def associations
          super | settings_social_accounts.keys.map(&:to_sym)
        end

        def translated_headers
          super | settings_social_accounts.values
        end

        def settings_social_accounts
          @settings_social_accounts ||= Import::SettingsFields.new(SocialAccount)
        end
      end

      def person_phone_numbers
        person.phone_numbers
      end

      def initialize(person)
        super
        add_social_accounts
      end

      def add_social_accounts
        fields = self.class.settings_social_accounts
        
        person.social_accounts.each do |account|
          hash[fields.key_for(account.label).to_sym] = account.value
        end
      end
    end
  end
end
