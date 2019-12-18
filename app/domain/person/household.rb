#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Household
  attr_reader :person, :ability, :other, :current_user

  def initialize(person, ability, other = nil, user = nil)
    @person = person
    @ability = ability
    @other = other
    @current_user = user
  end

  def valid?
    same_address?(person).tap do
      address_attrs(person).each do |attr, value|
        next if readonly_people.all? { |p| p.send(attr) == value }
        person.errors.add(attr, :readonly, name: "#{person.first_name} #{person.last_name}")
      end
    end
  end

  def empty?
    Array(person.household_people_ids).empty?
  end

  def same_address?(person)
    readonly_people.all? { |p| address_attrs(person) == address_attrs(p) }
  end

  def assign
    person.household_people_ids ||= housemates.collect(&:id)

    if readonly_people.empty?
      update_address
      update_people unless other == person
    elsif same_address?(other) || ability.can?(:update, other)
      update_people
    end
  end

  def persist!
    Person.transaction do
      empty? ? remove : save
    end
  end

  def save
    raise 'invalid' unless valid?
    if any_change?
      household_log(person, people, person.household_key?)
      person.update(household_key: key)
      housemates.each do |housemate|
        update_housemate(housemate, people, person)
      end
    end
  end

  def remove
    household_log_entry(person, people, :remove_from_household) if person.household_key?
    if people.size == 2
      household_log_entry(person, people, :remove_from_household, item: housemates.first)
      housemates.first.update(household_key: nil)
    end
    housemates.each do |housemate|
      household_log_entry(housemate, people, :remove_from_household, item: person)
    end
    person.update(household_key: nil)
  end

  def writable_people
    people - readonly_people
  end

  def readonly_people
    @readonly_people ||= housemates.select { |p| ability.cannot?(:update, p) }
  end

  def key
    @key ||= last_people_key || next_key
  end

  def address_changed?
    # for address changed in the form
    @address_changed
  end

  def people_changed?
    # for people changed in the form
    @people_changed
  end

  def changed_address_or_people?
    people.map { |p| [address_attrs(p), p.household_key] }.uniq.count > 1
  end

  def new_household?
    people.all? { |p| p.household_key.nil? }
  end

  def any_change?
    changed_address_or_people? || new_household?
  end

  def people
    housemates + [person]
  end

  def housemates
    person.household_people
  end

  private

  # NOTE: this may lead to inconsistency when params are manipulated
  def last_people_key
    (readonly_people + writable_people).collect(&:household_key).compact.last
  end

  def update_address
    unless address_attrs(person) == address_attrs(other)
      unless %w(plz town zip_code).all? { |attr| address_attrs(other)[attr].blank? }
        person.attributes = address_attrs(other)
        @address_changed = true
      end
    end
  end

  def address_attrs(person)
    person.attributes.slice(*Person::ADDRESS_ATTRS).transform_values do |val|
      val.blank? ? nil : val
    end
  end

  def update_people
    unless person.household_people_ids.include?(other.id.to_s)
      person.household_people_ids << other.id
      person.household_people_ids += other.household_people.collect(&:id)
      @people_changed = true
    end
  end

  def next_key
    loop do
      key = SecureRandom.uuid
      break key unless Person.where(household_key: key).exists?
    end
  end

  def update_housemate(housemate, people, person)
    people.delete(housemate)
    existing_household_key = housemate.household_key?
    housemate.update(address_attrs(person).merge(household_key: key))
    household_log(housemate, people, existing_household_key)
  end

  def household_log(housemate, _household, existing_household_key, options = {})
    item = options[:item] ? options[:item] : housemate
    if existing_household_key
      household_log_entry(housemate, people, :household_updated, item: item)
    else
      household_log_entry(housemate, people, :append_to_household, item: item)
    end
  end

  def household_log_entry(housemate, household, event, options = {})
    item = options[:item] ? options[:item] : housemate
    PaperTrail::Version.create(main: housemate,
                               item: item,
                               whodunnit: current_user.id,
                               event: event,
                               object_changes: household_name(household))
  end

  def household_name(household)
    household.map(&:full_name).join(', ')
  end

end
