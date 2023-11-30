# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class SelfRegistration::Housemate
  include ActiveModel::Model
  include ActiveModel::Validations
  extend ActiveModel::Naming

  class_attribute :required_attrs, default: [
    :first_name, :last_name, :email, :birthday
  ]
  class_attribute :attrs, default: required_attrs + [
    :gender, :primary_group_id, :household_key, :_destroy, :household_emails
  ]

  attr_accessor(*attrs)

  validate :assert_required_attrs
  validate :assert_email, if: -> { required_attrs.include?(:email) }
  validate :assert_person

  delegate :save!, :gender_label, to: :person

  def self.human_attribute_name(attr, options = {})
    Person.human_attribute_name(attr, options)
  end

  def self.reflect_on_association(*args)
    Person.reflect_on_association(*args)
  end

  def attributes
    attrs.index_with { |attr| send(attr) }.compact
  end

  def person
    Person.new(attributes.except(:_destroy, :household_emails))
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

  def assert_person
    person.then do |person|
      unless person.valid?
        (person.errors.attribute_names & attrs).each do |attr|
          errors.add(attr, person.errors[attr]) unless errors.key?(attr)
        end
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
end
