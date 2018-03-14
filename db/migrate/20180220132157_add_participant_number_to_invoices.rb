class AddParticipantNumberToInvoices < ActiveRecord::Migration
  def change
    add_column(:invoices, :participant_number, :string)
  end
end
