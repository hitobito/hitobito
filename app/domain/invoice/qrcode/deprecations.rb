#  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Previously, payee and recipient addresses were stored as free text
# and parsed during QR code generation.
# With the migration to structured address fields (payee_name, payee_street, etc.), this class
# enables generating QR codes for invoices still using the old format.
# For transparancy, payee and recipient_address have been renamed
# to deprecated_payee and deprecated_recipient_address.
class Invoice::Qrcode::Deprecations
  def initialize(invoice)
    @invoice = invoice
  end

  def deprecated_creditor?
    @invoice.payee_name.blank? && @invoice.deprecated_payee.present?
  end

  def deprecated_debitor?
    @invoice.recipient_name.blank? && @invoice.deprecated_recipient_address.present?
  end

  def creditor
    name, address_line1, address_line2 = parse_address(@invoice.deprecated_payee)
    {
      address_type: "K",
      name: name,
      address_line1: address_line1,
      address_line2: address_line2,
      zip_code: nil,
      town: nil,
      country: nil
    }
  end

  def debitor
    name, address_line1, address_line2 = parse_address(@invoice.deprecated_recipient_address)
    {
      address_type: "K",
      name: name,
      address_line1: address_line1,
      address_line2: address_line2,
      zip_code: nil,
      town: nil,
      country: nil
    }
  end

  private

  def parse_address(address)
    parts = address.to_s.strip.split(/\r*\n/)
    address_line1 = nil
    address_line2 = nil
    if parts.count > 1
      address_line1 = parts.last
    end
    if parts.count > 2
      address_line2 = address_line1
      address_line1 = parts.second_to_last
    end

    [parts.first, address_line1, address_line2]
  end
end
