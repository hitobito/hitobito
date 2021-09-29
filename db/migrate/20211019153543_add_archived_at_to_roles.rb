class AddArchivedAtToRoles < ActiveRecord::Migration[6.0]
  def change
    add_column :roles, :archived_at, :datetime
  end
end
