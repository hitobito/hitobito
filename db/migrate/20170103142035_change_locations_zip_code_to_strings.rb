class ChangeLocationsZipCodeToStrings < ActiveRecord::Migration
  def change
    change_column :locations, :zip_code, :string, null: false
  end
end
