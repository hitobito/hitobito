class RefillStructuredAddressesForNecessaryInvoices < ActiveRecord::Migration[8.0]
  def up
    Invoice.transaction do
      relevant_invoices.find_each do |invoice|
        # I dont know how exactly but there are invoices to recipient_ids that arent found. Presumably the people got deleted
        next unless invoice.recipient
        attributes = Contactable::Address.new(invoice.recipient).invoice_recipient_address_attributes
        invoice.attributes = attributes
        invoice.deprecated_recipient_address = nil
        invoice.save(validate: false)
      end
    end
  end

  def relevant_invoices
    Invoice.where(issued_at: Date.new(2025, 1, 1).all_year,
      recipient_type: Person.sti_name)
      .where("recipient_id IS NOT NULL")
      .includes(:recipient, :invoice_items, :invoice_run, recipient: :additional_addresses)
  end
end
