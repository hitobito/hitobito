class CreateHouseholdSequence < ActiveRecord::Migration[6.1]
  def up
    current_household_key = execute("SELECT COALESCE(MAX(household_key::integer) + 1, 1) FROM people").first['coalesce']

    execute <<-SQL
      CREATE SEQUENCE household_sequence
      START WITH #{current_household_key}
      INCREMENT BY 1
      NO MINVALUE
      NO MAXVALUE
      CACHE 1;
    SQL
  end

  def down
    execute <<-SQL
      DROP SEQUENCE IF EXISTS household_sequence;
    SQL
  end
end
