class AddDisclosureToEventQuestions < ActiveRecord::Migration[6.1]
  def change
    add_column(:event_questions, :disclosure, :string, null: true)

    reversible do |direction|
      direction.up do
        Event::Question.where(disclosure: nil).update_all(disclosure: :optional)
        Event::Question.where(required: true).update_all(disclosure:  :required)
      end
      direction.down do
        Event::Question.where(disclosure: :optional).update_all(required: false)
        Event::Question.where(disclosure: :required).update_all(required: true)
      end
    end

    change_column_null(:event_questions, :disclosure, false)
  end
end
