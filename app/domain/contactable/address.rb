# frozen_string_literal: true

#  Copyright (c) 2012-2024, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Contactable::Address
  def initialize(contactable, label: nil)
    @contactable = contactable
    @label = label
    @addressable = additional_addresses.find { |a| a.label == label } || contactable
  end

  def for_letter
    (contactable_and_company_name + full_address).compact.join("\n")
  end

  def for_letter_with_invoice
    with_invoice_addressable { for_letter }
  end

  def for_household_letter(members)
    [combine_household_names(members), full_address].compact.join("\n")
  end

  def for_pdf_label(name, nickname = false)
    names = if addressable.is_a?(AdditionalAddress)
      [addressable.name]
    else
      [
        (company_name if print_company?(name)),
        (contactable.nickname if print_nickname?(nickname)),
        name.presence
      ]
    end

    (names + full_address(country_as: :country_label)).compact.join("\n")
  end

  # Used to populate invoices#recipient_* fields, may be overridden in wagons
  def invoice_recipient_address_attributes
    with_invoice_addressable do
      {
        recipient_address_care_of: address_care_of,
        recipient_company_name: company? ? company_name : nil,
        recipient_name: (
          addressable.respond_to?(:full_name) ? addressable.full_name : addressable.name
        ).to_s.squish,
        recipient_street: street,
        recipient_housenumber: housenumber,
        recipient_postbox: postbox,
        recipient_zip_code: zip_code,
        recipient_town: town,
        recipient_country: country || default_country
      }
    end
  end

  # Used to populate invoices#payee_* fields, may be overridden in wagons
  def invoice_payee_address_attributes
    with_invoice_addressable do
      {
        payee_name: addressable.full_name.to_s.squish,
        payee_street: street,
        payee_housenumber: housenumber,
        payee_zip_code: zip_code,
        payee_town: town,
        payee_country: country || default_country
      }
    end
  end

  private

  attr_reader :contactable, :addressable

  delegate :address, :address_care_of, :postbox, :street, :housenumber, :zip_code, :town, :country,
    :name, :country_label, :ignored_country?, to: :addressable
  delegate :additional_addresses, :company_name, to: :contactable

  def company? = contactable.try(:company?)

  def full_name = addressable.respond_to?(:full_name) ? addressable.full_name : addressable.name

  def with_invoice_addressable
    original_addressable = @addressable
    @addressable = invoice_addressable
    yield
  ensure
    @addressable = original_addressable
  end

  def invoice_addressable
    @invoice_addressable ||= additional_addresses.find(&:invoices?) || contactable
  end

  def contactable_and_company_name
    if !addressable.is_a?(AdditionalAddress) && company?
      [company_name.to_s.squish, full_name.to_s.squish].uniq.compact_blank
    else
      [full_name.to_s.squish].compact_blank
    end
  end

  def combine_household_names(members)
    members.map(&:full_name).compact.join(", ")
  end

  def full_address(country_as: :country)
    [
      address_care_of.to_s.strip.presence,
      address.to_s.strip,
      postbox.to_s.strip.presence,
      zip_code_with_town,
      country_string(country_as)
    ].compact
  end

  def zip_code_with_town = [zip_code, town].compact.join(" ").squish

  def country_string(country_as) = ignored_country? ? "" : addressable.send(country_as)

  def default_country
    Settings.countries.prioritized.first
  end

  def company_name? = contactable.try(:company_name?)

  def print_company?(name)
    contactable.try(:company) && company_name? && company_name != name
  end

  def print_nickname?(nickname)
    nickname && contactable.respond_to?(:nickname) && contactable.nickname.present?
  end
end
