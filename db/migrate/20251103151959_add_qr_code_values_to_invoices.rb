class AddQrCodeValuesToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :qr_code_creditor_values, :string, array: true, null: false, default: Array.new(7)
    add_column :invoices, :qr_code_debitor_values, :string, array: true, null: false, default: Array.new(7)

    Invoice.reset_column_information

    # TOOD: check if this does not raise on int and production
    Invoice.find_each do |invoice|
      invoice.update!(
        qr_code_creditor_values: qr_code_values_for(invoice.payee),
        qr_code_debitor_values: qr_code_values_for(invoice.recipient_address),
      )
    end

    # TODO: drop payee

    # TODO: remove invoice config payee and add new columns street, housenumber, town, etc.
  end

  def qr_code_values_for(address)
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

    {
      address_type: "K",
      full_name: parts.first,
      address_line1: address_line1,
      address_line2: address_line2,
      zip_code: nil,
      town: nil,
      country: "CH"
    }.values
  end
end
