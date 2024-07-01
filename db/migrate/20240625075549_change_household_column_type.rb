class ChangeHouseholdColumnType < ActiveRecord::Migration[6.1]
  def up
    Person.all.each do |person|
      person.update_column(:household_key, person.household_key.to_i) if person.household_key.present?
    end

    change_column :people, :household_key, :integer, using: 'household_key::integer'
  end

  def down
    change_column :people, :household_key, :string
  end
end
