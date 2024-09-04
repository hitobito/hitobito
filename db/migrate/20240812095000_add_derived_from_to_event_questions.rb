class AddDerivedFromToEventQuestions < ActiveRecord::Migration[6.1]
  def change
    add_reference :event_questions, :derived_from_question, null: true,
                  foreign_key: false, type: :integer
  end
end
