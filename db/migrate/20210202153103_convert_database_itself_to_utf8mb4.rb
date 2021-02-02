# frozen_string_literal: true

class ConvertDatabaseItselfToUtf8mb4 < ActiveRecord::Migration[6.0]
  def up
    conn = ActiveRecord::Base.connection
    execute "ALTER DATABASE #{conn.quote_table_name(conn.current_database)} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"

    # convert tables again, to convert new ones as well
    conn.tables.each do |table|
      if table_is_not_utf8mb4(conn, table)
        execute "ALTER TABLE #{conn.quote_table_name(table)} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
      end
    end
  end

  def down
    # could raise ActiveRecord::IrreversibleMigration, but there is no point.
    # the migration is repeatable, but not reversible, therefore an empty down
  end

  private

  def table_is_not_utf8mb4(conn, table)
    conn.table_options(table)[:options]
        .match(/CHARSET=(?<charset>\w+)/)
       &.named_captures.to_h
        .fetch('charset', 'latin1') != 'utf8mb4'
  end
end
