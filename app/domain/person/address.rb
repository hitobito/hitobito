# frozen_string_literal: true

#  Copyright (c) 2012-2024, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Address
  INVOICE_LABEL = "Rechnung"

  def initialize(person, label: nil, name: nil)
    @person = person
    @name = name
    @addressable = find_addressable(label)
  end

  def for_letter
    (person_and_company_name + full_address).compact.join("\n")
  end

  # Intended to be overridden in wagons which have multiple addresses per person
  def for_invoice
    @addressable = find_addressable(INVOICE_LABEL)
    (person_and_company_name + short_address).compact.join("\n")
  end

  def for_household_letter(members)
    [combine_household_names(members), full_address].compact.join("\n")
  end

  def for_pdf_label(name, nickname = false)
    text = ""
    text += "#{@person.company_name}\n" if print_company?(name)
    text += "#{@person.nickname}\n" if print_nickname?(nickname)
    text += "#{name}\n" if name.present?
    text += address.to_s
    text += "\n" unless /\n\s*$/.match?(address)
    text += "#{zip_code} #{town}\n"
    text += country_label unless ignored_country?
    text
  end

  private

  attr_reader :person, :name, :label, :addressable

  delegate :address, :address_care_of, :postbox, :zip_code, :town, :country_label, :ignored_country?, to: :addressable

  def find_addressable(label) = @person.additional_addresses.find { |ad| ad.label == label } || @person

  def person_and_company_name
    if @person.company?
      [@person.company_name.to_s.squish, @person.full_name.to_s.squish].uniq.compact_blank
    else
      [@person.full_name.to_s.squish]
    end
  end

  def combine_household_names(members)
    members.map(&:full_name).compact.join(", ")
  end

  def full_address
    [
      address_care_of.to_s.strip.presence,
      address.to_s.strip,
      postbox.to_s.strip.presence,
      [zip_code, town].compact.join(" ").squish,
      country
    ].compact
  end

  def short_address
    [
      address.to_s.strip,
      [zip_code, town].compact.join(" ").squish,
      country
    ].compact
  end

  def country
    country = addressable.country.to_s.squish
    return if country.eql?(default_country)

    country
  end

  def default_country
    Settings.countries.prioritized.first
  end

  def print_company?(name)
    @person.try(:company) && @person.company_name? && @person.company_name != name
  end

  def print_nickname?(nickname)
    nickname && @person.respond_to?(:nickname) && @person.nickname.present?
  end
end
