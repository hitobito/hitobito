class RemoveParticipantNumberInternal < ActiveRecord::Migration[7.1]
  def change
    remove_column :invoice_configs, :participant_number_internal
    remove_column :invoices, :participant_number_internal
  end
end
