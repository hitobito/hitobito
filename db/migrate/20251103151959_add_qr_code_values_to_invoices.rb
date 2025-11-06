class AddQrCodeValuesToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :qr_payment_payee_address, :text
    add_column :invoices, :qr_payment_recipient_address, :text

    Invoice.reset_column_information

    # TOOD: check if this does not raise on int and production
    Invoice.find_each do |invoice|
      invoice.update!(
        qr_payment_payee_address: qr_code_address_for(invoice.payee),
        qr_payment_recipient_address: qr_code_address_for(invoice.recipient_address),
      )
    end

    # TODO: drop payee

    # TODO: remove invoice config payee and add new columns street, housenumber, town, etc.
  end

  def qr_code_address_for(address)
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

    Invoice::Qrcode::Address.new(**{
      address_type: "K",
      full_name: parts.first,
      street: address_line1,
      housenumber: address_line2,
      zip_code: nil,
      town: nil,
      country: "CH"
    })
  end
end
