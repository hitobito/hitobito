class AddEventTypeForGlobalQuestionsToEventQuestions < ActiveRecord::Migration[6.1]
  def change
    add_column :event_questions, :event_type, :string, null: true
  end
end
