# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::CsvPeople
  class ParticipationsFull < PeopleFull
    include ParticipationSupport
    
    def add_event_specifics
      questions.each { |question| merge!(:"question_#{question.id}" => question.question) }
      merge!(additional_information: additional_information_human) if additional_information.present?
    end

    private
    
    def questions
      participations.map(&:answers).flatten.map(&:question).uniq
    end

    def additional_information
      participations.map(&:additional_information).compact
    end

    def additional_information_human
      Event::Participation.human_attribute_name(:additional_information)
    end
  end
end
