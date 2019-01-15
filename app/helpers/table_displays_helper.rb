module TableDisplaysHelper

  def render_table_display_columns(table)
    current_person.table_display_for(parent).selected.each do |column|
      render_table_display_column(table, column)
    end
  end

  def render_table_display_column(table, column)
    if column =~ /^event_question_(\d+)$/
      question = parent.questions.find { |q| q.id == Regexp.last_match(1).to_i }
      TableDisplays::QuestionColumn.new(self, table: table, name: question).render if question
    else
      TableDisplays::Column.new(self, table: table, name: column).render
    end
  end

end
