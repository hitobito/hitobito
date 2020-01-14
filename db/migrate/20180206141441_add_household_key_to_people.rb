class AddHouseholdKeyToPeople < ActiveRecord::Migration[4.2]
  def change
    add_column(:people, :household_key, :string)
    add_index(:people, :household_key)
  end
end
