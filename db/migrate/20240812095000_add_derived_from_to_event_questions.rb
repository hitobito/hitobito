class AddDerivedFromToEventQuestions < ActiveRecord::Migration[6.1]
  def change
    Event::Question.reset_column_information
    add_reference :event_questions, :derived_from_question, null: true,
                  foreign_key: false, type: :integer
    reversible do |direction|
      direction.up { create_derived_questions }
      direction.down { delete_derived_questions }
    end
  end

  private

  def create_derived_questions
    Event::Question.where(event: nil).find_each do |global_question|
      Event::Question.transaction do
        existing_derived_questions = Event::Question.where(derived_from_question_id: global_question.id)
        existing_event_ids = Event.where.not(id: existing_derived_questions.pluck(:event_id)).pluck(:id)
        existing_event_ids.each do |event_id|
          derived_question = global_question.dup
          derived_question.update!(event_id: event_id, derived_from_question: global_question)
          Event::Answer.joins(:participation)
                       .where(participation: {event_id: event_id}, question_id: global_question.id)
                       .update_all(question_id: derived_question.id)
        end
      end
    end
  end

  def delete_derived_questions
    global_question_ids = Event::Question.where(event: nil).pluck(:id)
    global_question_ids.each do |global_question_id|
      derived_question_ids = Event::Question.where.not(derived_from_question_id: global_question_id).pluck(:id)
      Event::Answer.where(question_id: derived_question_ids).update_all(question_id: global_question_id)
      Event::Question.where(id: derived_question_ids).destroy_all
    end
  end
end
