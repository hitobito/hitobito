class RefillStructuredAddressesForNecessaryInvoices < ActiveRecord::Migration[8.0]
  # Define local models to avoid loading full models with concerns that reference
  # columns (like shipping_method) that may not exist yet in tenant schemas
  class MigrationInvoice < ActiveRecord::Base
    self.table_name = "invoices"
    belongs_to :recipient, polymorphic: true
  end

  def up
    MigrationInvoice.transaction do
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
    MigrationInvoice.where(created_at: year_range, recipient_type: "Person")
      .where("recipient_id IS NOT NULL")
      .includes(:recipient)
  end

  def year_range
    date = Date.new(2025, 1, 1)
    date.beginning_of_year.beginning_of_day..date.end_of_year.end_of_day
  end
end
