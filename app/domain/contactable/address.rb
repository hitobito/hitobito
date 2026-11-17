# frozen_string_literal: true

#  Copyright (c) 2012-2026, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Contactable::Address
  def initialize(contactable, category_key: nil)
    @contactable = contactable
    @addressable = additional_addresses.find { |a| a.category&.key == category_key } || contactable
  end

  def for_letter
    printed_address(contactable_and_company_name).lines.join("\n")
  end

  def for_letter_with_invoice
    with_invoice_addressable { for_letter }
  end

  def for_household_letter(members)
    printed_address([combine_household_names(members)], salutation: nil).lines.join("\n")
  end

  def for_pdf_label(name, nickname = false)
    address = printed_address(label_names(name, nickname))
    address = printed_address(label_names(name, false)) unless address.fits?
    address.lines.join("\n")
  end

  # Used to populate invoices#recipient_* fields, may be overridden in wagons
  def invoice_recipient_address_attributes # rubocop:disable Metrics/MethodLength
    with_invoice_addressable do
      recipient_first_name, recipient_last_name = recipient_name_parts
      {
        recipient_address_care_of: address_care_of,
        recipient_address_addition: address_addition,
        recipient_company_name: company? ? company_name : nil,
        recipient_first_name: recipient_first_name,
        recipient_last_name: recipient_last_name,
        recipient_street: street,
        recipient_housenumber: housenumber,
        recipient_postbox: postbox,
        recipient_zip_code: zip_code.to_s,
        recipient_town: town,
        recipient_country: country || default_country
      }
    end
  end

  # Used to populate invoices#payee_* fields, may be overridden in wagons
  def invoice_payee_address_attributes
    with_invoice_addressable do
      {
        payee_name: full_name.to_s.squish,
        payee_street: street,
        payee_housenumber: housenumber,
        payee_zip_code: zip_code,
        payee_town: town,
        payee_country: country || default_country
      }
    end
  end

  private

  def recipient_name_parts
    # If addressable is a Person with first_name and last_name, use those
    if addressable.respond_to?(:first_name) && addressable.respond_to?(:last_name)
      [addressable.first_name.to_s, addressable.last_name.to_s]
    else
      # Otherwise, store full name in last_name, first_name stays blank
      ["", full_name.to_s.squish]
    end
  end

  private

  attr_reader :contactable, :addressable

  delegate :address_care_of, :address_addition, :postbox, :street, :housenumber,
    :zip_code, :town, :country, :name, to: :addressable
  delegate :additional_addresses, to: :contactable

  def company? = addressable.try(:company?)

  def company_name = addressable.try(:company_name)

  def company_name? = addressable.try(:company_name?)

  def full_name = addressable.respond_to?(:full_name) ? addressable.full_name : addressable.name

  def with_invoice_addressable
    original_addressable = @addressable
    @addressable = invoice_addressable
    yield
  ensure
    @addressable = original_addressable
  end

  def invoice_addressable
    @invoice_addressable ||= additional_addresses.find { |a| a.category&.used_for_invoices? } ||
      contactable
  end

  def contactable_and_company_name
    if company?
      [company_name.to_s.squish, full_name.to_s.squish].uniq.compact_blank
    else
      [full_name.to_s.squish].compact_blank
    end
  end

  def combine_household_names(members)
    members.map(&:full_name).compact.join(", ")
  end

  def full_address = printed_address([], salutation: nil).all_lines

  # Printed above the names on letters and labels, may be overridden in wagons
  def printed_salutation = nil

  def printed_address(names, salutation: printed_salutation)
    PostalAddress::Printed.new(
      salutation:,
      names:,
      care_of: address_care_of,
      addition: address_addition,
      street:,
      housenumber:,
      postbox:,
      zip_code:,
      town:,
      country:
    )
  end

  def label_names(name, nickname)
    if addressable.is_a?(AdditionalAddress)
      [(company_name if company? && company_name?), full_name].uniq
    else
      [
        (company_name if print_company?(name)),
        (contactable.nickname if print_nickname?(nickname)),
        name.presence
      ]
    end
  end

  def default_country
    Settings.countries.prioritized.first
  end

  def print_company?(name)
    company? && company_name? && company_name != name
  end

  def print_nickname?(nickname)
    nickname && contactable.respond_to?(:nickname) && contactable.nickname.present?
  end
end
