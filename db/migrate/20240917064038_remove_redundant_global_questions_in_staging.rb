
# This migration can be removed after it has been deployed to staging
class RemoveRedundantGlobalQuestionsInStaging < ActiveRecord::Migration[6.1]
  def up
    redundant_global_questions.each do |redunant_question, original_question|
      # Any derived questions are duplicates aswell, so let's destroy them
      Event::Question.where(derived_from_question_id: redunant_question.id)
                     .destroy_all!

      redunant_question.destroy!
    end
  end

  def down
  end

  protected

  def redundant_global_questions
    global_question_translations = Event::Question.translation_class.joins(:globalized_model)
                                                  .where(event_questions: { event_id: nil })
                                                  .order(created_at: :ASC)

    first_of_each, duplicates_of_first = {}, {}
    global_question_translations.find_each do |translation|
      if first_of_each[translation.question].blank?
        # The first time we encounter this question, store it as the original
        first_of_each[translation.question] ||= translation.globalized_model
      else
        # Every consecutive time we encounter the question, store it as duplicate with ref to original
        duplicates_of_first[translation.globalized_model] = first_of_each[translation.question]
      end
    end
    duplicates_of_first
  end
end
