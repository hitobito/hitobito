# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Household

  include ActiveModel::Model

  attr_reader :household_key, :new_people, :remove_people

  with_options on: :update do
    validates_with Households::MembersValidator
    validate :validate_members
  end

  def initialize(reference_person)
    @reference_person = reference_person
    init_defaults

    if @household_key
      @members = fetch_members
    else
      @household_key = init_household_key
      @members = []
      add(@reference_person)
    end
  end

  def warnings
    @warnings ||= ActiveModel::Errors.new(self)
  end

  def add(person)
    @new_people << person
  end

  def remove(person)
    @remove_people << person
  end

  def valid?(context = :update)
    super(context)
  end

  def save(context: :update)
    return false unless valid?(context)

    ActiveRecord::Base.transaction do
      save_removed
      save_members
      @new_people = []
      @remove_people = []
      true
    end
  end

  def destroy
    @members.each {|m| remove(m.person) }
    save(context: :destroy)
  end

  def reload
    initialize(@reference_person.reload)
    self
  end

  def members
    @members.concat(HouseholdMember.from(new_people, self))
    @members.reject! {|m| remove_people.collect(&:id).include?(m.person.id) }
    @members.uniq { |m| m.person.id }
  end

  def people
    members.collect(&:person)
  end

  def household_members_attributes=(attributes)
    attr_ids = attributes.map { |a| a[:person_id] }

    attr_ids.each do |person_id|
      add(Person.find(person_id)) unless person_ids.include?(person_id)
    end

    person_ids.each do |person_id|
      remove_by_id(person_id) unless attr_ids.include?(person_id)
    end
  end

  private

  def remove_by_id(person_id)
    person = people.find { |p| p.id == person_id }
    remove(person)
  end

  def person_ids
    members.collect { |m| m.person.id }
  end

  def init_household_key
    loop do
      key = SecureRandom.uuid
      break key unless Person.where(household_key: key).exists?
    end
  end

  def save_removed
    Person.where(household_key: @household_key)
      .where.not(id: person_ids)
      .update_all(household_key: nil)
  end

  def save_members
    Person.where(id: person_ids).update_all(household_attrs)
  end

  def household_attrs
    attrs = { household_key: @household_key }
    address_attrs = @reference_person.attributes
      .slice(*Person::ADDRESS_ATTRS).transform_values do |val|
        val.presence
      end
    attrs.merge(address_attrs)
  end

  def fetch_members
    members = Person.where(household_key: @household_key)
    HouseholdMember.from(members, self)
  end

  def init_defaults
    @new_people = []
    @remove_people = []
    @household_key = @reference_person.household_key
  end

  def validate_members
    @members.each_with_index do |member, index|
      unless member.valid?
        member.errors.each do |error|
          errors.add("members[#{index}].#{error.attribute}", error.message)
        end
      end
    end
  end

end
