#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class ParticipationsFull < PeopleFull
    self.row_class = ParticipationRow

    def build_attribute_labels
      labels = super
      questions.each { |question| labels[:"question_#{question.id}"] = question.question }
      labels[:participation_additional_information] =
        Event::Participation.human_attribute_name(:additional_information)
      labels[:created_at] = Event::Participation.human_attribute_name(:created_at)
      labels
    end

    private

    def people
      list.map(&:person)
    end

    def questions
      list.map(&:answers).flatten.map(&:question).uniq
    end
  end
end
