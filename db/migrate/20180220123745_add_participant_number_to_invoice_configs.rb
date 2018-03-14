class AddParticipantNumberToInvoiceConfigs < ActiveRecord::Migration
  def change
    add_column(:invoice_configs, :participant_number, :string)
  end
end
