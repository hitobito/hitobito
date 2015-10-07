class FixEventKindGlobalizedFields < ActiveRecord::Migration
  def up
    Event::Kind.add_translation_fields!({ general_information: :text }, migrate_data: true)
    Event::Kind.add_translation_fields!({ application_conditions: :text }, migrate_data: true)
    Event::Kind.add_translation_fields!({ documents_text: :text }, migrate_data: true)

    remove_column :event_kinds, :general_information
    remove_column :event_kinds, :application_conditions
    remove_column :event_kinds, :documents_text
  end

  def down
    fail 'translation data will be lost!'

    add_column(:event_kinds, :general_information, :text)
    add_column(:event_kinds, :application_conditions, :text)
    add_column(:event_kinds, :documents_text, :text)

    remove_column :event_kind_translations, :general_information
    remove_column :event_kind_translations, :application_conditions
    remove_column :event_kind_translations, :documents_text
  end
end
