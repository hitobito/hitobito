class SetRolesStartEndFromTimestamps < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE roles
          SET
            start_on = created_at,
            end_on = COALESCE(deleted_at, delete_on)
        SQL
      end
    end
  end
end
