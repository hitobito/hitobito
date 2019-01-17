module Export::Tabular::People
  class TableDisplays < PeopleAddress
    self.model_class = ::Person
    self.row_class = TableDisplayRow

    attr_reader :table_display

    def initialize(list, table_display)
      super(list)
      @table_display = table_display
    end

    def build_attribute_labels
      person_attribute_labels.merge(association_attributes).merge(selected_labels)
    end

    def selected_labels
      filtered_selection.each_with_object({}) do |attr, hash|
        hash[attr] = attribute_label(attr)
      end
    end

    def row_for(entry, format = nil)
      return row_class.new(entry, table_display, format) unless participations?

      Export::Tabular::People::TableDisplayParticipationRow.new(entry, table_display, format)
    end

    def human_attribute(attr)
      return super unless attr =~ TableDisplay::Participations::QUESTION_REGEX
      Event::Question.find(Regexp.last_match(1)).question
    end

    def people
      participations? ? list.map(&:person) : list
    end

    def questions
      list.map(&:answers).flatten.map(&:question).uniq
    end

    def participations?
      table_display.is_a?(TableDisplay::Participations)
    end

    def filtered_selection
      keys = participations? ? with_selected_questions : selected
      keys.collect(&:to_sym) - person_attributes
    end

    def selected
      table_display.selected
    end

    def with_selected_questions
      without_questions = selected - selected.grep(TableDisplay::Participations::QUESTION_REGEX)
      without_questions + table_display.selected_questions(questions.collect(&:id)).collect(&:first)
    end

  end
end
