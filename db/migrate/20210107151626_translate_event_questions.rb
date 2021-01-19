class TranslateEventQuestions < ActiveRecord::Migration[6.0]
  def up
    say_with_time('creating translation table for event-questions') do
      Event::Question.create_translation_table!(
        {
          question: :string,
          choices: :string
        },
        { migrate_data: true, remove_source_columns: true }
      )
    end
  end

  def down
    say_with_time('dropping translation-table for event-questions') do
      Event::Question.drop_translation_table! migrate_data: true
    end
  end
end
