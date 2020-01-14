class AddReferenceToPayments < ActiveRecord::Migration[4.2]
  def change
    add_column(:payments, :reference, :string)
  end
end
