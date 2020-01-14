class AddParticipantNumberToInvoices < ActiveRecord::Migration[4.2]
  def change
    add_column(:invoices, :participant_number, :string)
  end
end
