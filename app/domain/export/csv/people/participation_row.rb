# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv::People
  class ParticipationRow < Export::Csv::People::PersonRow
    dynamic_attributes[/^question_\d+$/] = :question_attribute

    def initialize(participation)
      @participation = participation
      super(participation.person)
    end

    def roles
      @participation.roles.map { |role| role  }.join(', ')
    end

    def additional_information
      @participation.additional_information
    end

    def created_at
      I18n.l(@participation.created_at.to_date)
    end

    def question_attribute(attr)
      _, id = attr.to_s.split('_', 2)
      answer = @participation.answers.find { |e| e.question_id == id.to_i }
      answer.try(:answer)
    end
  end
end
