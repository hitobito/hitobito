class CreateStandardQuestionsForEventQuestions < ActiveRecord::Migration[6.1]
  def change
    add_reference:event_questions, :derived_from_question, null: true,
      type: :integer, # default is :bigint, which does not match id
      foreign_key: { to_table: :event_questions }

    reversible do |direction|
      direction.up { create_derived_questions }
      direction.down { delete_derived_questions }
    end
  end

  private

  def create_derived_questions
    standard_question_ids = Event::Question.where(event: nil).find_each(&)
  end

  def delete_derived_questions
    standard_question_ids = Event::Question.where(event: nil).pluck(:id)
    standard_question_ids.each do |standard_question_id|
      derived_question_ids = Event::Question.where.not(derived_from_question_id: standard_question_id).pluck(:id)
      Event::Answer.where(question_id: derived_question_ids).update_all(question_id: standard_question_id)
      Event::Question.where(id: derived_question_ids).destroy_all # or delete_all
    end
  end
end
