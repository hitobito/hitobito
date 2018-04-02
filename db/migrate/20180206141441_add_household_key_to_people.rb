class AddHouseholdKeyToPeople < ActiveRecord::Migration
  def change
    add_column(:people, :household_key, :string)
    add_index(:people, :household_key)
  end
end
