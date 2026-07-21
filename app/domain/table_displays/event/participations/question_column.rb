# frozen_string_literal: true

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
          event.questions.pluck(:id).map { |id|
            "event_question_#{id}"
          }
        end.uniq
      end
    end

    def required_model_attrs(_attr)
      []
    end

    def label(attr)
      Event::Question.find(question_id(attr)).label
    end

    def render(attr)
      super do |answer, answer_attr|
        answer.send(answer_attr) if answer.present?
      end
    end

    def sort_by(attr)
      # disable sorting for event question answers for now, may be fixed with https://github.com/hitobito/hitobito/issues/2955
      # id = question_id(attr)
      # "event_questions.id = #{id} ASC, TRIM(event_answers.answer)" if id
    end

    protected

    def allowed?(object, attr, _original_object, _original_attr)
      Event::Question::VisibleList.new(
        event: object.event, ability: ability, participation: object, cache: visible_list_cache
      ).questions.map(&:id).include?(question_id(attr).to_i)
    end

    def question_id(attr)
      attr[QUESTION_REGEX, 1]
    end

    private

    def allowed_value_for(target, target_attr, &block)
      target = target.answers.find do |answer|
        answer.question_id.to_s == question_id(target_attr)
      end
      target_attr = :answer

      super
    end

    # Shared across every #allowed? call of this column instance, which lives for a whole
    # table render. Avoids re-querying the event's questions and the viewer's event roles
    def visible_list_cache
      @visible_list_cache ||= {}
    end
  end
end
