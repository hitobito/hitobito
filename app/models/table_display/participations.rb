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

  def table_model_class
    Event::Participation
  end

  def with_permission_check(object, path)
    return super unless path =~ QUESTION_REGEX

    if ability.can?(:update, object.event) || ability.can?(:show_full, object.person)
      yield(*resolve(object, path))
    end
  end

  def sort_statements(parent)
    question_sort_statements(parent).merge(person_sort_statements.to_h)
  end

  def selected_questions(question_ids)
    selected.collect do |column|
      next unless column =~ QUESTION_REGEX
      id = Regexp.last_match(1).to_i
      [column, id] if question_ids.include?(id)
    end.compact
  end

  def person_sort_statements
    selected.grep(/person/).collect do |key|
      [key, key.gsub('person', 'people')]
    end.to_h
  end

  def question_sort_statements(question_ids)
    selected_questions(question_ids).collect do |column, id|
      [column, "CASE event_questions.id WHEN #{id} THEN 0 ELSE 1 END, TRIM(event_answers.answer)"]
    end.to_h
  end

  protected

  def known?(attr)
    super || attr =~ QUESTION_REGEX
  end
end
