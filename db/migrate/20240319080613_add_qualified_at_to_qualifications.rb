class AddQualifiedAtToQualifications < ActiveRecord::Migration[6.1]
  def change
    change_table(:qualifications) do |t|
      t.date :qualified_at
    end

    reversible do |dir|
      dir.up { execute "UPDATE qualifications SET qualified_at = start_at" }
    end
  end
end
