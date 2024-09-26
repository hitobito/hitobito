
# frozen_string_literal: true

class DeriveQuestionService
  def create_derived_questions
    Event::Question.transaction do
      Event::Question.where(event: nil).find_each do |global_question|
        existing_derived_questions = Event::Question.where(derived_from_question_id: global_question.id)
        existing_event_ids = Event.where(type: global_question.event_type)
                                  .where.not(id: existing_derived_questions.pluck(:event_id)).pluck(:id)
        existing_event_ids.each do |event_id|
          derived_question = global_question.dup
          derived_question.update!(event_id: event_id, derived_from_question: global_question,
                                  skip_add_answer_to_participations: true)
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
