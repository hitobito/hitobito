class ConvertDatabaseToUtf8mb4 < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.connection.tables.each do |table|
      execute "ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
    end
  end

  def down
    # could raise ActiveRecord::IrreversibleMigration, but there is no point
  end
end
