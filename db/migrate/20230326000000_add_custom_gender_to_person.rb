class AddCustomGenderToPerson < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :gender_custom, :string, null: true
    Person.reset_column_information
  end
end
