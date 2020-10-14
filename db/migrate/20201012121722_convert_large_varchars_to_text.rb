class ConvertLargeVarcharsToText < ActiveRecord::Migration[6.0]
  def up
    db_conn.tables.each do |table_name|
      large_varchar_columns(table_name).each do |column|
        change_column table_name, column.name, :text,
                      null: column.null,
                      default: column.default
      end
    end
  end

  def down
    # could raise ActiveRecord::IrreversibleMigration, but there is no point.
    # the migration is repeatable, but not reversible, therefore an empty down
  end

  private

  def db_conn
    @db_conn ||= ActiveRecord::Base.connection
  end

  def large_varchar_columns(table_name)
    db_conn.columns(table_name).select do |col|
      col.type == :string && col.limit > 255
    end
  end
end
