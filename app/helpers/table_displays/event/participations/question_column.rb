#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays::Event::Participations
  class QuestionColumn < TableDisplays::MultiColumn
    QUESTION_REGEX = /^event_question_(\d+)$/

    class << self
      def can_display?(attr)
        attr =~ QUESTION_REGEX
      end

      def available(list)
        list.map(&:event).uniq.flat_map do |event|
          event.question_ids.map { |id| "event_question_#{id}" }
        end.uniq
      end
    end

    def required_model_attrs(attr)
      []
    end

    def value_for(object, attr)
      target, target_attr = resolve(object, attr)
      if target.present? && target_attr.present? && allowed?(target, target_attr)
        target = target.answers.find do |answer|
          answer.question_id.to_s == question_id(target_attr)
        end
        target_attr = :answer

        return target, target_attr unless block_given?
        yield target, target_attr
      end
    end

    def label(attr)
      Event::Question.find(question_id(attr)).label
    end

    def render(attr)
      super do |answer, answer_attr|
        answer.send(answer_attr)
      end
    end

    def sort_by(attr)
      id = question_id(attr)
      "CASE event_questions.id WHEN #{id} THEN 0 ELSE 1 END, TRIM(event_answers.answer)" if id
    end

    protected

    def allowed?(object, attr)
      ability.can?(:update, object.event) || ability.can?(:show_full, object.person)
    end

    def question_id(attr)
      attr[QUESTION_REGEX, 1]
    end
  end
end
