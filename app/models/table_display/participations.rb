# == Schema Information
#
# Table name: table_displays
#
#  id        :integer          not null, primary key
#  selected  :text(16777215)
#  type      :string(255)      not null
#  person_id :integer          not null
#
# Indexes
#
#  index_table_displays_on_person_id_and_type  (person_id,type) UNIQUE
#

class TableDisplay::Participations < TableDisplay
  QUESTION_REGEX = /^event_question_(\d+)$/

  def available
    people_columns
  end

  def people_columns
    TableDisplay::People.new.available.collect do |column|
      "person.#{column}"
    end
  end

  def with_permission_check(object, path)
    return super unless QUESTION_REGEX.match?(path)

    if ability.can?(:update, object.event) || ability.can?(:show_full, object.person)
      yield(*resolve(object, path))
    end
  end

  def sort_statements(parent)
    question_sort_statements(parent).merge(person_sort_statements.to_h)
  end

  def selected_questions(question_ids)
    selected.collect { |column|
      next unless column =~ QUESTION_REGEX
      id = Regexp.last_match(1).to_i
      [column, id] if question_ids.include?(id)
    }.compact
  end

  def person_sort_statements
    selected.grep(/person/).collect { |key|
      [key, key.gsub("person", "people")]
    }.to_h
  end

  def question_sort_statements(question_ids)
    selected_questions(question_ids).collect { |column, id|
      [column, "CASE event_questions.id WHEN #{id} THEN 0 ELSE 1 END, TRIM(event_answers.answer)"]
    }.to_h
  end
end
