# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Household
  include ActiveModel::Model
  include ActiveModel::Dirty

  attr_reader :household_key, :members, :reference_person, :warnings

  define_attribute_methods :members

  def initialize(reference_person)
    @reference_person = reference_person
    @household_key = @reference_person.household_key
    @warnings = ActiveModel::Errors.new(self)

    if persisted?
      # for an existing household, fetch the members
      @members = fetch_members
    else
      # build a new household with the single member `reference_person`
      @members = []
      add(reference_person)
    end
  end

  validates_with Households::MembersValidator, on: :update
  validate :validate_members

  def add(person)
    return if members.any? { |m| m.person == person }

    attribute_will_change!(:members)
    members << HouseholdMember.new(person, self)
    self
  end

  def remove(person)
    return unless members.any? { |m| m.person == person }

    attribute_will_change!(:members)
    members.reject! { |m| m.person == person }
    self
  end

  def valid?(context = :update)
    super
  end

  def save!(context: :update, &)
    raise "error saving household" unless save(context:, &)
  end

  def save(context: :update, &)
    return false unless valid?(context)

    members.clear if members.size < 2
    save_records(&)
    changes_applied # resolve dirty status
    true
  end

  def destroy
    attribute_will_change!(:members)
    members.clear
    save(context: :destroy) do |_, removed_people|
      yield removed_people if block_given?
    end
  end

  def reload
    # reload the reference person as it might have been updated on DB
    # (e.g. by calling #remove(reference_person) on the household and saving)
    p = reference_person.reload
    # make sure to clear ALL instance variables as we are reusing the instance
    instance_variables.each { remove_instance_variable(_1) }
    # also reset dirty tracking
    clear_changes_information
    # re-initialize the instance with the reloaded reference person
    initialize(p)
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

  def address_attrs
    address.attrs
  end

  def new_record?
    # if the reference person has no household key, the household must be new
    household_key.blank?
  end

  def persisted?
    !new_record?
  end

  alias_method :exists?, :persisted?

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
    Sequence.increment!('household_sequence')
  end

  def save_records
    ActiveRecord::Base.transaction do
      new_household = new_record? # remember value before persisting
      save_removed
      save_members
      yield new_people, removed_people if block_given?
      Households::LogEntries.new(self, new_household).create!
    end
  end

  def save_removed
    removed_people.each { |person| person.update!(household_key: nil) }
  end

  def save_members
    return if members.blank? # prevents generating key for empty household

    # generate a fresh key if we don't have one yet
    @household_key ||= next_key
    people.each { |person| person.update!(address_attrs.merge(household_key:)) }
    # reload the reference_person as this is a different reference to the same person in `people`
    # which does not know the updated attributes yet.
    @reference_person.reload
  end

  def fetch_members
    members = Person.where(household_key: reference_person.household_key)
    HouseholdMember.from(members, self)
  end

  def validate_members
    members.each_with_index do |member, index|
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
