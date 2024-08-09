class AddStartEndToRoles < ActiveRecord::Migration[6.1]
  def change
    change_table :roles, bulk: true do |t|
      t.timestamp :start_at
      t.timestamp :end_at
    end
  end
end
