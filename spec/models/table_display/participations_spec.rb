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

  context :with_permission_check do
    let(:participation) { event_participations(:top) }

    it 'yields if person is may show_full on person' do
      person = Fabricate(Group::BottomLayer::Leader.sti_name.to_sym, group: groups(:bottom_layer_one)).person
      subject = TableDisplay.for(person, participation.event)
      expect { subject.with_permission_check('event_question_1', participation) }.to raise_error(LocalJumpError)
    end

    it 'yields if person is a event leader' do
      person = Fabricate(Event::Role::Leader.sti_name, participation: Fabricate(:event_participation, event: top_course)).person
      subject = TableDisplay.for(person, participation.event)
      expect { subject.with_permission_check('event_question_1', participation) }.to raise_error(LocalJumpError)
    end

    it 'noops if person is a event participant' do
      person = Fabricate(Event::Role::Participant.sti_name, participation: Fabricate(:event_participation, event: top_course)).person
      subject = TableDisplay.for(person, participation.event)
      expect { subject.with_permission_check('event_question_1', participation) }.not_to raise_error(LocalJumpError)
    end
  end
end
