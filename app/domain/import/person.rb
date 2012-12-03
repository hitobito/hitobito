module Import
  class Person
    extend Forwardable
    attr_reader :person, :hash, :phone_numbers, :social_accounts
    def_delegators :person, :persisted?, :save, :id, :errors

    BLACKLIST = [:contact_data_visible,
                 :created_at,
                 :current_sign_in_at,
                 :current_sign_in_ip,
                 :encrypted_password,
                 :id,
                 :last_sign_in_at,
                 :last_sign_in_ip,
                 :picture,
                 :remember_created_at,
                 :reset_password_sent_at,
                 :reset_password_token,
                 :sign_in_count,
                 :last_label_format_id,
                 :updated_at]


    def self.fields
      all = person_attributes + 
        Import::SettingsFields.new(PhoneNumber).fields + 
        Import::SettingsFields.new(SocialAccount).fields

      all.sort_by { |entry| entry[:value] } 
    end

    def self.person_attributes
      # alle attributes - technische attributes
      [::Person.column_names - BLACKLIST.map(&:to_s)].flatten.map! do |name|
        { key: name, value: ::Person.human_attribute_name(name, default: '') }
      end
    end
    
    def initialize(hash)
      prepare(hash)

      create_person
      phone_numbers.each { |number| person.phone_numbers.build(number) } 
      social_accounts.each { |account| person.social_accounts.build(account) } 
    end

    def add_role(group, role_type)
      return if person.roles.any? { |role| role.group == group && role.type == role_type } 
      role = person.roles.build
      role.group = group
      role.type = role_type
    end

    def human_errors
      person.errors.messages.map do |key, value|
        key == :base ? value : "#{::Person.human_attribute_name(key)} #{value.join}"
      end.flatten.join(', ')
    end

    private
    def prepare(hash)
      @hash = hash.with_indifferent_access
      @phone_numbers = extract_settings_fields(PhoneNumber, :number)
      @social_accounts = extract_settings_fields(SocialAccount, :name)
    end

    def create_person
      @person = DoubletteFinder.new(hash).find_and_update || ::Person.new(hash)
    end

    def extract_settings_fields(model, value_key)
      keys = Import::SettingsFields.new(model).keys
      numbers = keys.select { |key| hash.has_key?(key) } 
      numbers.map do |key| 
        label = key.split('_').last.capitalize
        value = hash.delete(key)
        { value_key => value, :label => label } if value.present?
      end.compact
    end

    class DoubletteFinder
      attr_reader :attrs

      DOUBLETTE_ATTRIBUTES = [
        :first_name,
        :last_name,
        :zip_code,
        :birthday
      ]

      def initialize(attrs)
        @attrs = attrs
      end

      def query
        criteria = attrs.select { |key, value| value.present? && DOUBLETTE_ATTRIBUTES.include?(key.to_sym) } 
        criteria.delete(:birthday) unless parse_date(criteria[:birthday])

        conditions = ['']
        criteria.each do |key, value|
          conditions.first << " AND " if conditions.first.present?
          conditions.first << "#{key} = ?"
          value = parse_date(value) if key.to_sym == :birthday
          conditions << value
        end

        if attrs[:email].present?
          if conditions.first.present?
            conditions[0] = "(#{conditions[0]}) OR "
          end
          conditions.first << "email = ?"
          conditions << attrs[:email]
        end
        conditions
      end
      
      def find_and_update
        conditions = query
        return if conditions.first.blank? 
        people = ::Person.includes(:roles).where(conditions).to_a

        if people.present? 
          person = people.first
          if people.size == 1
            blank_attrs = attrs.select {|key, value| person.attributes[key].blank? } 
            person.attributes = blank_attrs
          else
            person.errors.add(:base, "#{people.size} Treffer in Duplikatserkennung.")
          end
          person
        end
      end

      private
      def parse_date(date_string)
        if date_string.present?
          begin
            Time.zone.parse(date_string).to_date
          rescue ArgumentError
          end
        end
      end
    end
  end

end
