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
    options = conn.table_options(table)

    charset =
      options[:charset] || # AR 6.1
      charset_from_options(options) || # AR 6.0
      'latin1'

    charset != 'utf8mb4'
  end

  def charset_from_options(options)
    options[:options]
      .match(/CHARSET=(?<charset>\w+)/)
     &.named_captures.to_h
      .fetch('charset', nil)
  end
end
