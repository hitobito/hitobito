class AddTerminatedToRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :roles, :terminated, :boolean, null: false, default: false
  end
end
