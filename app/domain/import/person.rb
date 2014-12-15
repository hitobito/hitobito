# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Import
  class Person

    delegate :save, :new_record?, to: :person

    attr_reader :person, :attributes, :override,
                :phone_numbers, :social_accounts, :additional_emails

    class << self
      def fields
        all = person_attributes +
          Import::ContactAccountFields.new(AdditionalEmail).fields +
          Import::ContactAccountFields.new(PhoneNumber).fields +
          Import::ContactAccountFields.new(SocialAccount).fields

        all.sort_by { |entry| entry[:value] }
      end

      def person_attributes
        relevant_attributes.map! do |name|
          { key: name, value: ::Person.human_attribute_name(name, default: '') }
        end
      end

      # alle attributes - technische attributes
      def relevant_attributes
        ::Person.column_names -
          ::Person::INTERNAL_ATTRS.map(&:to_s) -
          %w(picture primary_group_id)
      end
    end

    def initialize(person, attributes, override = false)
      @person = person
      @override = override
      prepare(attributes)
    end

    def populate
      assign_attributes
      assign_accounts(additional_emails, person.additional_emails)
      assign_accounts(phone_numbers, person.phone_numbers)
      assign_accounts(social_accounts, person.social_accounts)
    end

    def add_role(group, role_type)
      return if person.roles.any? { |role| role.group == group && role.type == role_type.sti_name }

      role = person.roles.build
      role.group = group
      role.type = role_type.sti_name
      role
    end

    def human_errors
      person.errors.messages.map do |key, value|
        key == :base ? value : "#{::Person.human_attribute_name(key)} #{value.join(', ')}"
      end.flatten.join(', ')
    end

    def valid?
      person.errors.empty? && person.valid?
    end

    # assert that csv does not contain emails multiple times.
    def email_unique?(imported_emails)
      if person.email?
        case imported_emails[person.email]
        when person.object_id
          true
        when nil
          imported_emails[person.email] = person.object_id
          true
        else
          person.errors.add(:email, :taken)
          false
        end
      else
        true
      end
    end

    private

    def prepare(attributes)
      @attributes = attributes
      @additional_emails = extract_contact_fields(AdditionalEmail)
      @phone_numbers = extract_contact_fields(PhoneNumber)
      @social_accounts = extract_contact_fields(SocialAccount)
    end

    def assign_attributes
      person.attributes =
        if override
          attributes
        else
          attributes.select { |key, _v| person.attributes[key].blank? }
        end
    end

    def assign_accounts(accounts, association)
      accounts.each do |imported|
        existing = association.detect { |a| a.label == imported[:label] }
        if existing
          existing.attributes = imported if override
        else
          association.build(imported)
        end
      end
    end

    def extract_contact_fields(model)
      keys = ContactAccountFields.new(model).keys
      accounts = keys.select { |key| attributes.key?(key) }
      accounts.map do |key|
        label = key.split('_').last.capitalize
        value = attributes.delete(key)
        { model.value_attr => value, :label => label } if value.present?
      end.compact
    end

  end

end
