# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class ParticipationRow < PersonRow

    attr_reader :participation

    delegate :additional_information, to: :participation, prefix: true

    dynamic_attributes[/^question_\d+$/] = :question_attribute

    def initialize(participation, format = nil)
      @participation = participation
      super(participation.person, format)
    end

    def roles
      participation.roles.map { |role| role }.join(', ')
    end

    def created_at
      normalize(participation.created_at.to_date)
    end

    def question_attribute(attr)
      _, id = attr.to_s.split('_', 2)
      answer = participation.answers.find { |e| e.question_id == id.to_i }
      answer.try(:answer)
    end

  end
end
