class AddSortNameToPerson < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      ALTER TABLE people
      ADD COLUMN sort_name VARCHAR
      GENERATED ALWAYS AS (
        CASE
          WHEN company IS TRUE THEN company_name
          WHEN last_name IS NOT NULL THEN last_name
          WHEN first_name IS NOT NULL THEN first_name
          WHEN nickname IS NOT NULL THEN nickname
          ELSE ''
        END
      ) STORED;
    SQL
  end

  def down
    remove_column :people, :sort_name
  end
end
