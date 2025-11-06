#  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::Qrcode::Address < Data.define(:address_type, :full_name, :street, :housenumber,
  :zip_code, :town, :country)
  VALID_ADDRESS_TYPES = ["K", "S"]

  def initialize(**params)
    normalized = params.transform_values { |v| v&.to_s&.strip }

    unless VALID_ADDRESS_TYPES.include?(normalized[:address_type])
      raise "Unknown address type '#{params[:address_type]}'"
    end

    super(**normalized)
  end

  def readable_address
    if address_type == "K"
      readable_address_unstructured
    else
      readable_address_structured
    end
  end

  private

  # For QR Code Payments, unstructured addresses are not valid anymore,
  # but kept to render old invoices.
  def readable_address_unstructured
    [
      full_name,
      street,
      housenumber
    ].compact.join("\n")
  end

  def readable_address_structured
    [
      full_name,
      [street, housenumber].compact.join(" "),
      [zip_code, town].compact.join(" ")
    ].compact_blank.join("\n")
  end
end
