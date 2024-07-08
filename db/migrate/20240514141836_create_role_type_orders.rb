class CreateRoleTypeOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :role_type_orders do |t|
      t.string :name
      t.integer :order_weight

      t.timestamps
    end
  end
end
