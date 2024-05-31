# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Households::Address

  delegate :reference_person, :people, to: :'@household'

  def initialize(household)
    @household = household
  end

  def attrs
    extract_attrs(address_from_person)
  end

  def oneline
    address = attrs.dup
    street_and_number = if FeatureGate.enabled?('structured_addresses')
                          [address[:street], address[:housenumber]].compact_blank.join(' ')
                        else
                          address[:address].to_s
                        end

    [
      street_and_number.strip,
      [address[:zip_code], address[:town]].compact.join(' ').squish
    ].join(', ')
  end

  def dirty?
    household_attrs = attrs.except(:country)
    people.any? do |person|
      extract_attrs(person).except(:country) != household_attrs
    end
  end

  private

  def extract_attrs(person)
    person.attributes
      .slice(*Person::ADDRESS_ATTRS).transform_values do |val|
        val.presence
      end.with_indifferent_access
  end

  def address_from_person
    address_person = reference_person
    people.each do |p|
      if complete_address?(p)
        address_person = p
      end
    end
    address_person
  end

  def complete_address?(person)
    person.address.present? ||
      (person.zip_code.present? && person.town.present?)
  end

end
