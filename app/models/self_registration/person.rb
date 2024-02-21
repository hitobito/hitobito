# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::Person
  include ActiveModel::Model
  include ActiveModel::Attributes

  class_attribute :required_attrs, default: [
    :first_name, :last_name, :email, :birthday
  ]
  class_attribute :attrs, default: required_attrs + [
    :gender, :primary_group, :household_key, :_destroy, :household_emails
  ]
  class_attribute :active_model_only, default: []

  def initialize(attributes = {})
    # We call `define_attributes` here, because we want to be able to override the attributes
    # in the wagon customizations by setting the class attributes `:attrs` and `:required_attrs`.
    define_attributes

    # Let's simply ignore unknown attributes.
    super(attributes.with_indifferent_access.slice(*self.class.attribute_names))
  end

  def self.define_attributes
    # Let's make sure we don't define the attributes over and over again.
    return if @attributes_defined

    (required_attrs + attrs).each { |attr| attribute attr }
    required_attrs.each { |attr| validates attr, presence: true }
    @attributes_defined = true
  end
  delegate :define_attributes, to: :class

  # As we call `define_attributes` in the initializer, the attributes will only be defined
  # in the instance, but not in the class. So we need to override `attribute_names` here and
  # make sure the attributes are defined, otherwise the method will return an empty array until
  # the first instance is initialized.
  def self.attribute_names
    define_attributes
    super
  end

  validate :assert_email, if: -> { email.present? }
  validate :assert_person_valid
  validate :assert_role_valid, if: :primary_group

  def self.human_attribute_name(attr, options = {})
    super(attr, default: Person.human_attribute_name(attr, options))
  end

  def self.reflect_on_association(*args)
    Person.reflect_on_association(*args)
  end

  delegate :gender_label, to: :person

  def save!
    person.save! && role.save! && enqueue_duplicate_locator_job
  end

  def person
    @person ||= Person.new(attributes)
  end

  def role
    @role ||= Role.new(person: person, group: primary_group, type: role_type)
  end

  def attr?(attr_name)
    attribute_names.include?(attr_name.to_s)
  end

  def household_emails
    Array.wrap(attributes['household_emails'])
  end

  private

  def enqueue_duplicate_locator_job
    ::Person::DuplicateLocatorJob.new(person.id).enqueue!
  end

  def attributes
    super.except(*active_model_only.collect(&:to_s))
  end

  def assert_email
    unless Truemail.validate(email.to_s, with: :regex).result.success
      errors.add(:email, :invalid)
    end

    unless Person.where(email: email).none? && household_emails.to_a.count(email) <= 1
      errors.add(:email, I18n.t('activerecord.errors.models.person.attributes.email.taken'))
    end
  end

  def assert_role_valid
    unless role.valid?
      role.errors.attribute_names.each do |attr|
        errors.add(attr, role.errors[attr].join(', '))
      end
    end
  end

  def assert_person_valid
    unless person.valid?
      (person.errors.attribute_names & attrs).each do |attr|
        errors.add(attr, person.errors[attr].join(', ')) unless errors.key?(attr)
      end
    end
  end

  def role_type
    primary_group.self_registration_role_type
  end
end
