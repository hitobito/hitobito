# frozen_string_literal: true

class ConvertDatabaseToUtf8mb4 < ActiveRecord::Migration[6.0]
  def up
    conn = ActiveRecord::Base.connection

    charset = 'CHARACTER SET utf8mb4 COLLATE utf8mb4_bin'

    conn.tables.each do |table|
      next if table == 'ar_internal_metadata'

      execute "ALTER TABLE #{table} CONVERT TO #{charset}"

      conn.columns(table).each do |column|
        case column.sql_type.downcase
        when 'varchar(255)'
          length = if has_index?(conn, table, column.name)
                     191
                   else
                     255
                   end

          execute "ALTER TABLE #{table} MODIFY COLUMN #{conn.quote_column_name(column.name)} VARCHAR(#{length}) #{charset}"
        when /varchar\(\d*\)/, 'text'
          if column.limit > 191 && has_index?(conn, table, column.name)
            raise <<~ERROR_MESSAGE
              big column with index: #{table}.#{column.name}

              we need to change the table-options to include ROW_FORMAT=DYNAMIC
            ERROR_MESSAGE
          end

          execute "ALTER TABLE #{table} MODIFY COLUMN #{conn.quote_column_name(column.name)} #{column.sql_type.upcase} #{charset}"
        end
      end
    end
  end

  def down
    # could raise ActiveRecord::IrreversibleMigration, but there is no point
  end

  def has_index?(conn, table_name, column_name)
    conn.indexes(table_name).any? do |idx|
      idx.columns.include?(column_name)
    end
  end
end
