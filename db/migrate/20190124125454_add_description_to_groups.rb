class AddDescriptionToGroups < ActiveRecord::Migration[4.2]
  def change
    unless column_exists?(:groups, :description)
      add_column(:groups, :description, :text)
    end
  end
end
