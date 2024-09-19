class AddTypeToEventQuestions < ActiveRecord::Migration[6.1]
  def change
    add_column(:event_questions, :type, :string, null: true, index: true)

    reversible do |direction|
      direction.up do
        Event::Question.update_all(type: "Event::Question::Default")
      end
    end

    change_column_null(:event_questions, :type, false)
  end
end
