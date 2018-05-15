class AddReferenceToPayments < ActiveRecord::Migration
  def change
    add_column(:payments, :reference, :string)
  end
end
