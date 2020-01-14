class AddParticipantNumberToInvoiceConfigs < ActiveRecord::Migration[4.2]
  def change
    add_column(:invoice_configs, :participant_number, :string)
  end
end
