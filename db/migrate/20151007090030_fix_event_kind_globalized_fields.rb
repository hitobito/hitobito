class FixEventKindGlobalizedFields < ActiveRecord::Migration
  def up
    Event::Kind.add_translation_fields!({ general_information: :text }, migrate_data: true)
    remove_column :event_kinds, :general_information

    Event::Kind.add_translation_fields!({ application_conditions: :text }, migrate_data: true)
    remove_column :event_kinds, :application_conditions
  end

  def down
    add_column(:event_kinds, :general_information, :text)
    add_column(:event_kinds, :application_conditions, :text)

    remove_column :event_kind_translations, :general_information
    remove_column :event_kind_translations, :application_conditions
  end
end
