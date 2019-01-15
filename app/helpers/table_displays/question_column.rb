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
