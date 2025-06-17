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
    @label = label
    @addressable = additional_addresses.find { |a| a.label == label } || person
  end

  def for_letter
    (person_and_company_name + full_address).compact.join("\n")
  end

  # Use to populate invoices#recipient_address, might be overriden in wagons
  def for_invoice
    @addressable = additional_addresses.find(&:invoices?) || person
    (person_and_company_name + short_address).compact.join("\n")
  end

  def for_household_letter(members)
    [combine_household_names(members), full_address].compact.join("\n")
  end

  def for_pdf_label(name, nickname = false)
    names = if addressable.is_a?(AdditionalAddress)
      [addressable.name]
    else
      [
        (person.company_name if print_company?(name)),
        (person.nickname if print_nickname?(nickname)),
        name.presence
      ]
    end

    [
      *names,
      short_address(country_as: :country_label)
    ].compact.join("\n")
  end

  private

  attr_reader :person, :name, :addressable

  delegate :address, :address_care_of, :postbox, :zip_code, :town, :name, :country_label, :ignored_country?, to: :addressable
  delegate :company?, :additional_addresses, to: :person

  def person_and_company_name
    return [name, address_care_of].compact_blank if addressable.is_a?(AdditionalAddress)

    if company?
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
      zip_code_with_town,
      country_string(:country)
    ].compact
  end

  def short_address(country_as: :country)
    [
      address.to_s.strip,
      zip_code_with_town,
      country_string(country_as)
    ].compact
  end

  def zip_code_with_town = [zip_code, town].compact.join(" ").squish

  def country_string(country_as) = ignored_country? ? "" : addressable.send(country_as)

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
