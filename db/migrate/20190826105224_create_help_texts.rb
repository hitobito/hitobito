class CreateHelpTexts < ActiveRecord::Migration
  def change
    create_table :help_texts do |t|
      t.string :controller_name, null: false
      t.string :entry_class, null: true
      t.string :key, null: false
    end
    add_index(:help_texts, [:controller_name, :key], unique: true)

    reversible do |dir|
      dir.up   { HelpText.create_translation_table!(body: :text) }
      dir.down { HelpText.drop_translation_table! }
    end
  end
end
