class TranslateEventQuestions < ActiveRecord::Migration[6.0]
  def up
    Event::Question.create_translation_table!(
      {
        question: :string,
        choices: :string
      },
      { migrate_data: true }
    )

    remove_column :event_questions, :question
    remove_column :event_questions, :choices
  end

  def down
    add_column :event_questions, :question, :string
    add_column :event_questions, :choices, :string
    Event::Question.drop_translation_table! migrate_data: true
  end
end
