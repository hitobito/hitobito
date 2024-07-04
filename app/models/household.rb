# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Household
  include ActiveModel::Model
  include ActiveModel::Dirty

  attr_reader :household_key, :members, :reference_person

  define_attribute_methods :members

  def initialize(reference_person)
    @reference_person = reference_person
    init_defaults

    if @household_key
      @members = fetch_members
    else
      @household_key = next_key
      add(@reference_person)
    end
  end

  validates_with Households::MembersValidator, on: :update
  validate :validate_members

  def add(person)
    return if members.any? { |m| m.person == person }

    attribute_will_change!(:members)
    members << HouseholdMember.new(person, self)
  end

  def remove(person)
    return unless members.any? { |m| m.person == person }

    attribute_will_change!(:members)
    members.reject! { |m| m.person == person }
  end

  def valid?(context = :update)
    super
  end

  def save!(context: :update)
    raise "error saving household" unless save(context: context)
  end

  def save(context: :update)
    return false unless valid?(context)

    members.clear if members.size < 2

    ActiveRecord::Base.transaction do
      yield new_people, removed_people if block_given?
      save_removed
      save_members
      Households::LogEntries.new(self).create!
      changes_applied
      true
    end
  end

  def destroy
    attribute_will_change!(:members)
    members.clear
    save(context: :destroy) do |_, removed_people|
      yield removed_people if block_given?
    end
  end

  def reload
    initialize(@reference_person.reload)
    self
  end

  def people
    members.collect(&:person)
  end

  def new_people
    return [] unless changes[:members]

    (members - members_was).map(&:person)
  end

  def removed_people
    return [] unless changes[:members]

    (members_was - members).map(&:person)
  end

  def warnings
    @warnings ||= ActiveModel::Errors.new(self)
  end

  def address_attrs
    address.attrs
  end

  def new_record?
    @reference_person.household_key.nil?
  end

  def destroy?
    members.none?
  end

  def empty?
    members.one?
  end

  private

  def address
    Households::Address.new(self)
  end

  def person_ids
    members.collect { |m| m.person.id }
  end

  def next_key
    loop do
      key = SecureRandom.uuid
      break key unless Person.exists?(household_key: key)
    end
  end

  def save_removed
    Person.where(id: removed_people.map(&:id)).update_all(household_key: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  def save_members
    Person.where(id: person_ids).find_each do |p|
      p.update!(household_attrs)
    end
  end

  def household_attrs
    attrs = {household_key: @household_key}
    attrs.merge(address_attrs)
  end

  def fetch_members
    members = Person.where(household_key: @household_key)
    HouseholdMember.from(members, self)
  end

  def init_defaults
    @members = []
    @household_key = @reference_person.household_key
  end

  def validate_members
    @members.each_with_index do |member, index|
      member.validate(validation_context)
      member.errors.each do |error|
        errors.add("members[#{index}].#{error.attribute}", error.message)
      end
      member.warnings.each do |warning|
        warnings.add("members[#{index}].#{warning.attribute}", warning.message)
      end
    end
  end
end
