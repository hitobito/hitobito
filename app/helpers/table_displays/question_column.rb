#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class QuestionColumn < Column
    delegate :content_tag, :check_box_tag, :label_tag, to: :template

    def render
      super if question
    end

    delegate :label, to: :question

    def format_attr(target, _)
      target.answers.find { |answer| answer.question == @question }.try(:answer)
    end

    def header
      table.sort_header(template.dom_id(@question), label)
    end

    def question
      @question ||= template.parent.questions.find { |q| q.id == question_id.to_i }
    end

    def question_id
      @question_id ||= name[TableDisplay::Participations::QUESTION_REGEX, 1]
    end
  end
end
