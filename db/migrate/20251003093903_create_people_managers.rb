class CreatePeopleManagers < ActiveRecord::Migration[7.1]
  def change
    create_table(:people_managers, if_not_exists: true) do |t|
      t.integer :manager_id, null: false
      t.integer :managed_id, null: false

      t.timestamps

      t.index [:manager_id, :managed_id], unique: true
    end
  end
end
