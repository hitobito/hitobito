module Import
  class Person
    extend Forwardable
    attr_reader :person, :hash, :phone_numbers, :social_accounts
    def_delegators :person, :persisted?, :save

    def self.fields
      all = person_attributes + 
        Import::SettingsFields.new(PhoneNumber).fields + 
        Import::SettingsFields.new(SocialAccount).fields

      all.sort_by { |entry| entry[:value] } 
    end

    def initialize(hash)
      prepare(hash)

      create_person
      phone_numbers.each { |number| person.phone_numbers.build(number) } 
      social_accounts.each { |account| person.social_accounts.build(account) } 
    end

    def add_role(group, role_type)
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
      @person = ::Person.new(hash)
    end

    def extract_settings_fields(model, value_key)
      keys = Import::SettingsFields.new(model).keys
      numbers = keys.select { |key| hash.has_key?(key) } 
      numbers.map do |key| 
        label = key.split('_').last.capitalize
        { value_key => hash.delete(key), :label => label } 
      end
    end

    BLACKLIST = [:contact_data_visible,
                 :created_at,
                 :current_sign_in_at,
                 :current_sign_in_ip,
                 :encrypted_password,
                 :id,
                 :last_sign_in_at,
                 :last_sign_in_ip,
                 :remember_created_at,
                 :reset_password_sent_at,
                 :reset_password_token,
                 :sign_in_count,
                 :updated_at]

    def self.person_attributes
      # alle attributes - technischen attributes

      [::Person.column_names - BLACKLIST.map(&:to_s)].flatten.map! do |name|
        { key: name, value: ::Person.human_attribute_name(name, default: '') }
      end
    end
  end

end
