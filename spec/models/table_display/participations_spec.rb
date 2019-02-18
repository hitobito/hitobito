require 'spec_helper'

describe TableDisplay::Participations do
  let(:top_course) { events(:top_course) }
  let(:question)   { event_questions(:top_ov) }

  it 'translates person columns for sort statements' do
    subject.selected = %w(name person.birthday)
    expect(subject.person_sort_statements).to eq('person.birthday' => 'people.birthday')
  end

  it 'builds custom sort statements for questions' do
    subject.selected = %W(event_question_1 event_question_#{question.id} event_question_2)
    statements = subject.question_sort_statements(top_course.question_ids)
    expect(statements).to have(1).item
    expect(statements["event_question_#{question.id}"]).to eq 'CASE event_questions.id ' \
      "WHEN #{question.id} THEN 0 ELSE 1 END, TRIM(event_answers.answer)"
  end

end
