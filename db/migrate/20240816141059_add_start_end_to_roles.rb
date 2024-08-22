class AddStartEndToRoles < ActiveRecord::Migration[6.1]
  def change
    change_table :roles, bulk: true do |t|
      t.date :start_on
      t.date :end_on
    end
  end
end
