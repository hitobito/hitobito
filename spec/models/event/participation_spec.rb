# encoding: utf-8
# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer          not null
#  person_id              :integer          not null
#  additional_information :text
#  created_at             :datetime
#  updated_at             :datetime
#  active                 :boolean          default(FALSE), not null
#  application_id         :integer
#  qualified              :boolean
#

require 'spec_helper'

describe Event::Participation do


  let(:course) do
    course = Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk))
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course
  end


  context '#init_answers' do
    subject { course.participations.new }

    context do
      before { subject.init_answers }

      it 'creates answers from event' do
        subject.answers.collect(&:question).to_set.should == course.questions.to_set
      end
    end

    it 'does not save associations in database' do
      expect { subject.init_answers }.not_to change { Event::Answer.count }
      expect { subject.init_answers }.not_to change { Event::Participation.count }
    end
  end

  context 'mass assignments' do
    subject { course.participations.new }

    it 'assigns application and answers for new record' do
      q = course.questions
      subject.person_id = 42
      subject.attributes = {
            additional_information: 'bla',
            application_attributes: { priority_2_id: 42 },
            answers_attributes: [{ question_id: q[0].id, answer: 'ja' },
                                 { question_id: q[1].id, answer: 'nein' }] }

      subject.additional_information.should == 'bla'
      subject.answers.should have(2).items
    end

    it 'assigns participation and answers for persisted record' do
      p = Person.first
      subject.person = p
      subject.save!

      q = course.questions
      subject.attributes = {
            additional_information: 'bla',
            application_attributes: { priority_2_id: 42 },
            answers_attributes: [{ question_id: q[0].id, answer: 'ja' },
                                 { question_id: q[1].id, answer: 'nein' }] }

      subject.person_id.should == p.id
      subject.additional_information.should == 'bla'
      subject.answers.should have(2).items
    end
  end


end
