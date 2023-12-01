# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class SelfRegistration::Housemate
  include ActiveModel::Model

  class_attribute :required_attrs, default: [
    :first_name, :last_name, :email, :birthday
  ]
  class_attribute :attrs, default: required_attrs + [
    :gender, :primary_group, :household_key, :_destroy, :household_emails
  ]

  attr_accessor(*attrs)

  delegate :gender_label, to: :person

  validate :assert_required_attrs
  validate :assert_email, if: -> { required_attrs.include?(:email) }
  validate :assert_person_valid
  validate :assert_role_valid, if: :primary_group

  def self.human_attribute_name(attr, options = {})
    Person.human_attribute_name(attr, options)
  end

  def self.reflect_on_association(*args)
    Person.reflect_on_association(*args)
  end

  def attributes
    attrs.index_with { |attr| send(attr) }.compact
  end

  def save!
    person.save! && role.save!
  end

  def person
    @person ||= Person.new(attributes.except(:_destroy, :household_emails))
  end

  def role
    @role ||= Role.new(person: person, group: primary_group, type: role_type)
  end

  private

  def assert_email
    unless Truemail.validate(email.to_s, with: :regex).result.success
      errors.add(:email, :invalid)
    end

    unless Person.where(email: email).none? && household_emails.to_a.count(email) <= 1
      errors.add(:email, :taken)
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

  def assert_required_attrs
    present = required_attrs.collect do |attr|
      send(attr).present?.tap do |value|
        errors.add(attr, :blank) if value.blank?
      end
    end
    present.all?
  end

  def role_type
    primary_group.self_registration_role_type
  end
end
