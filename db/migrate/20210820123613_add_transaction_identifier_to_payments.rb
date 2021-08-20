class AddTransactionIdentifierToPayments < ActiveRecord::Migration[6.0]
  def change
    add_column :payments, :transaction_identifier, :string
  end
end
