class AddDisclosureToEventQuestions < ActiveRecord::Migration[6.1]
  def change
    add_column(:event_questions, :disclosure, :integer, null: true)
    add_column(:event_questions, :type, :boolean, null: true)

    reversible do |direction|
      direction.up do
        Event::Question.where(required: true).update_all(disclosure: :required)
        Event::Question.where(required: false).update_all(disclosure: :optional)
      end
      direction.down do
        Event::Question.where(disclosure: :required).update_all(required: true)
        Event::Question.where(disclosure: :optional).update_all(required: false)
      end
    end

    change_column_null(:event_questions, :disclosure, false)
  end
end
