#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class ParticipationsFull < PeopleFull
    self.row_class = ParticipationRow
    self.styled_attrs = {
      date: [:birthday, :created_at]
    }

    def build_attribute_labels
      labels = super
      labels.merge! questions_labels
      labels[:participation_additional_information] =
        Event::Participation.human_attribute_name(:additional_information)
      labels[:created_at] = Event::Participation.human_attribute_name(:created_at)
      labels
    end

    def questions_labels
      questions.map { |question| [:"question_#{question.id}", question.question] }.to_h
    end

    private

    def questions
      Event::Question.joins(answers: :participation)
        .where(event_participations: {id: pluck_ids_from_list("event_participations.id")})
    end

    def people_ids
      @people_ids ||= pluck_ids_from_list(
        :participant_id,
        @list.where(participant_type: Person.sti_name)
      )
    end
  end
end
