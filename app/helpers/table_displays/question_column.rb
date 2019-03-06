#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class QuestionColumn < Column

    delegate :content_tag, :check_box_tag, :label_tag, to: :template

    def label
      question.question
    end

    def render
      header = table.sort_header(template.dom_id(question), question.question)
      table.col(header) do |participation|
        participation.answers.find { |answer| answer.question == question }.try(:answer)
      end
    end

    def question
      name
    end
  end
end
