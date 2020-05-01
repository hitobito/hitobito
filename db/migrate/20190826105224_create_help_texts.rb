class CreateHelpTexts < ActiveRecord::Migration[4.2]
  def change
    create_table :help_texts do |t|
      t.string :controller, null: false, limit: 100
      t.string :model,      null: true,  limit: 100
      t.string :kind,       null: false, limit: 100
      t.string :name,       null: false, limit: 100
    end
    add_index :help_texts, [:controller, :model, :kind, :name], unique: true, name: 'index_help_texts_fields'

    reversible do |dir|
      dir.up   { HelpText.create_translation_table!(body: :text) }
      dir.down { HelpText.drop_translation_table! }
    end
  end
end
