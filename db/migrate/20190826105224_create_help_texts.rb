class CreateHelpTexts < ActiveRecord::Migration
  def change
    create_table :help_texts do |t|
      t.string :controller, null: false
      t.string :model, null: true
      t.string :kind, null: false
      t.string :name, null: false
    end
    add_index :help_texts, [:controller, :model, :kind, :name], unique: true, name: 'index_help_texts_fields'

    reversible do |dir|
      dir.up   { HelpText.create_translation_table!(body: :text) }
      dir.down { HelpText.drop_translation_table! }
    end
  end
end
