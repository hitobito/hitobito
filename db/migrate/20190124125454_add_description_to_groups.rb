class AddDescriptionToGroups < ActiveRecord::Migration
  def change
    unless column_exists?(:groups, :description)
      add_column(:groups, :description, :text)
    end
  end
end
