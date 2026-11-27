# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# The person registering for an event via API. An existing person is matched by email only;
# only the updatable attributes are taken over. Validation must not reveal whether a person exists.
class Event::ApiRegistration::Applicant
  class_attribute :updatable_attributes, default: []

  def self.person_attributes
    Event.possible_contact_attrs.map { |attr| api_attribute(attr) }.uniq
  end

  def self.api_attribute(contact_attr)
    (contact_attr.to_sym == :phone_numbers) ? :phone_number : contact_attr.to_sym
  end

  attr_reader :event, :values

  def initialize(event, values, privacy_policy_accepted: nil)
    @event = event
    @values = values.to_h.symbolize_keys.slice(*self.class.person_attributes)
      .transform_values { |value| value.is_a?(String) ? value.strip : value }
      .compact_blank
    @privacy_policy_accepted = privacy_policy_accepted
  end

  def validate(errors)
    validate_required(errors)
    validate_hidden(errors)
    validate_email(errors)
    validate_person(errors)
    validate_privacy_policy(errors)
  end

  def person
    @person ||= existing_person || build_person
  end

  def existing_person?
    existing_person.present?
  end

  def updates
    return {} unless existing_person?

    values.slice(*updatable_attributes)
  end

  private

  def existing_person
    return @existing_person if defined?(@existing_person)

    @existing_person = Person.find_by(email: values[:email].downcase) if values[:email]
  end

  def build_person
    Person.new(values.except(:phone_number, :language)).tap do |person|
      person.language = values[:language] || I18n.locale.to_s
      if privacy_policy_finder.acceptance_needed?
        person.privacy_policy_accepted = @privacy_policy_accepted
      end
      if values[:phone_number]
        person.phone_numbers.build(number: values[:phone_number],
          category: Event::Guest.phone_number_category)
      end
    end
  end

  def validate_required(errors)
    required_attributes.each { |attr| errors.add(attr, :blank) if values[attr].blank? }
  end

  def validate_hidden(errors)
    event.hidden_contact_attrs.map { |attr| self.class.api_attribute(attr) }.each do |attr|
      errors.add(attr, :not_allowed) if values.key?(attr)
    end
  end

  def validate_email(errors)
    return if values[:email].blank? || Devise.email_regexp.match?(values[:email])

    errors.add(:email, :invalid)
  end

  def validate_person(errors)
    candidate = build_person
    return if candidate.valid?

    candidate.errors.each do |error|
      next if error.type == :taken || error.type == :name_missing

      attribute = person_error_attribute(error.attribute)
      next if errors.of_kind?(attribute, error.type)

      errors.add(attribute, error.type, message: error.message)
    end
  end

  def validate_privacy_policy(errors)
    return if privacy_policy_finder.accepted?(@privacy_policy_accepted)

    errors.add(:privacy_policy_accepted, :accepted)
  end

  def privacy_policy_finder
    @privacy_policy_finder ||= Group::PrivacyPolicyFinder.for(group: event.groups.first)
  end

  def required_attributes
    (event.class.mandatory_contact_attrs + event.required_contact_attrs)
      .map { |attr| self.class.api_attribute(attr) }.uniq
  end

  def person_error_attribute(attribute)
    return :phone_number if attribute.to_s.start_with?("phone_numbers")

    self.class.person_attributes.include?(attribute) ? attribute : :base
  end
end
