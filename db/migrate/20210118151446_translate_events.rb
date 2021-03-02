class TranslateEvents < ActiveRecord::Migration[6.0]
  def up
    unless ActiveRecord::Base.connection.table_exists?('event_translations')
      say_with_time('creating translation table for events') do
        Event.create_translation_table!(
          {
            name: :string,
            description: :text,
            application_conditions: :text,
            signature_confirmation_text: :string
          },
          { migrate_data: true, remove_source_columns: true }
        )
      end
    end
  end

  def down
    say_with_time('dropping translation-table for events') do
      Event.drop_translation_table! migrate_data: true
    end

    change_column_null :events, :name, false
  end
end
