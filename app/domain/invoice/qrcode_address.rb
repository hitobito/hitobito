#  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::QrcodeAddress
  KEYS = [:address_type, :full_name, :street, :housenumber, :zip_code, :town, :country]
  VALID_ADDRESS_TYPES = ["K", "S"]

  def initialize(values)
    if VALID_ADDRESS_TYPES.exclude? values.first
      raise "Uknown address type '#{values.first}'"
    end

    if values.length != KEYS.length
      raise "Expected exactly #{KEYS.length} values, got #{values.length}"
    end

    @values = KEYS.zip(values).to_h
  end

  def to_h
    @values
  end

  def readable_address
    if @values[:address_type] == "K"
      readable_address_unstructured
    else
      readable_address_structured
    end
  end

  private

  # For QR Code Payments, unstructured addresses are not valid anymore,
  # but kept to render old invoices.
  def readable_address_unstructured
    name = stripped_value(:full_name)
    address_line1 = stripped_value(:street)
    address_line2 = stripped_value(:housenumber)

    [
      name,
      address_line1,
      address_line2
    ].compact.join("\n")
  end

  def readable_address_structured
    name = stripped_value(:full_name)
    street = stripped_value(:street)
    housenumber = stripped_value(:housenumber)
    zip_code = stripped_value(:zip_code)
    town = stripped_value(:town)

    [
      name,
      [street, housenumber].compact.join(" "),
      [zip_code, town].compact.join(" ")
    ].map(&:presence).compact.join("\n")
  end

  def stripped_value(key)
    @values[key]&.strip
  end
end
