class AddDerivedFromToEventQuestions < ActiveRecord::Migration[6.1]
  def change
    add_reference :event_questions, :derived_from_question, null: true,
                  foreign_key: false, type: :integer
    reversible do |direction|
      direction.up { create_derived_questions }
      direction.down { delete_derived_questions }
    end
  end

  private

  def create_derived_questions
    Event::Question.where(event: nil).find_each(&:derive_for_existing_events)
  end

  def delete_derived_questions
    standard_question_ids = Event::Question.where(event: nil).pluck(:id)
    standard_question_ids.each do |standard_question_id|
      derived_question_ids = Event::Question.where.not(derived_from_question_id: standard_question_id).pluck(:id)
      Event::Answer.where(question_id: derived_question_ids).update_all(question_id: standard_question_id)
      Event::Question.where(id: derived_question_ids).destroy_all
    endd
end
