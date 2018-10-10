class AddParticipantNumberInternalToInvoiceConfigs < ActiveRecord::Migration
  def change
    add_column :invoice_configs, :participant_number_internal, :string
    add_column :invoices, :participant_number_internal, :string
  end
end
