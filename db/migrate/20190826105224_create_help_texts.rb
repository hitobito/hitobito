class CreateHelpTexts < ActiveRecord::Migration
  def up
    create_table :help_texts do |t|
      t.string :controller_name, null: false
      t.string :entry_class, null: true
      t.string :key, null: false

      t.timestamps
    end
    HelpText.create_translation_table!(
      {
        body: :text
      }
    )

    HelpText.globalize_migrator.drop_translations_index
    remove_index(HelpText.globalize_migrator.translations_table_name,
                 name: HelpText.globalize_migrator.translation_locale_index_name)
    HelpText.globalize_migrator.create_translations_index
  end

  def down
    drop_table :help_texts
    HelpText.drop_translation_table!
  end
end
