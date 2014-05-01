# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Import
  class Person
    extend Forwardable
    def_delegators :person, :persisted?, :save, :id, :errors

    attr_reader :person, :hash, :phone_numbers, :social_accounts, :additional_emails, :emails

    BLACKLIST = [:contact_data_visible,
                 :created_at,
                 :creator_id,
                 :updated_at,
                 :updater_id,
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
                 :failed_attempts,
                 :locked_at,
                 :last_label_format_id,
                 :primary_group_id]


    def self.fields
      all = person_attributes +
        ContactAccountFields.new(AdditionalEmail).fields +
        ContactAccountFields.new(PhoneNumber).fields +
        ContactAccountFields.new(SocialAccount).fields

      all.sort_by { |entry| entry[:value] }
    end

    def self.person_attributes
      # alle attributes - technische attributes
      [::Person.column_names - BLACKLIST.map(&:to_s)].flatten.map! do |name|
        { key: name, value: ::Person.human_attribute_name(name, default: '') }
      end
    end

    def initialize(hash, emails)
      @emails = emails
      prepare(hash)

      find_or_initialize_person
      assign_additional_emails
      assign_phone_numbers
      assign_social_accounts
    end

    def add_role(group, role_type)
      return if person.roles.any? { |role| role.group == group && role.is_a?(role_type) }
      role = person.roles.build
      role.group = group
      role.type = role_type.sti_name
      role
    end

    def human_errors
      person.errors.messages.map do |key, value|
        key == :base ? value : "#{::Person.human_attribute_name(key)} #{value.join}"
      end.flatten.join(', ')
    end

    # comply with db uniq index constraint on email
    def valid?
      person.email ? (person.valid? && email_valid?) : person.valid?
    end

    private

    def prepare(hash)
      @hash = hash.with_indifferent_access
      @additional_emails = extract_settings_fields(AdditionalEmail)
      @phone_numbers = extract_settings_fields(PhoneNumber)
      @social_accounts = extract_settings_fields(SocialAccount)
    end

    def find_or_initialize_person
      @person = PersonDoubletteFinder.new(hash).find_and_update || ::Person.new(hash)
    end

    def assign_additional_emails
      assign_accounts(additional_emails, person.additional_emails) do |existing, imported|
        existing.email == imported[:email]
      end
    end

    def assign_phone_numbers
      assign_accounts(phone_numbers, person.phone_numbers) do |existing, imported|
        existing.number == imported[:number]
      end
    end

    def assign_social_accounts
      assign_accounts(social_accounts, person.social_accounts) do |existing, imported|
        existing.name == imported[:name] && existing.label == imported[:label]
      end
    end

    def assign_accounts(accounts, association)
      accounts.each do |imported|
        unless association.any? { |a| yield a, imported }
          association.build(imported)
        end
      end
    end

    def extract_settings_fields(model)
      keys = ContactAccountFields.new(model).keys
      numbers = keys.select { |key| hash.key?(key) }
      numbers.map do |key|
        label = key.split('_').last.capitalize
        value = hash.delete(key)
        { model.value_attr => value, :label => label } if value.present?
      end.compact
    end

    def email_valid?
      if emails.include?(person.email)
        person.errors.add(:email, :taken)
        false
      else
        (emails << person.email) && true
        true
      end
    end
  end

end
