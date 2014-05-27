# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipantAssigner do

  let(:course) do
    course = Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk))
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course
  end

  let(:participation) { Fabricate(:event_participation, event: course, application: Fabricate(:event_application)) }

  let(:event) { course }

  subject { Event::ParticipantAssigner.new(event, participation) }

  describe '#create_role' do

    before do
      participation.init_answers
      participation.save!
    end

    it 'creates role for given application' do
      expect { subject.create_role }.to change { Event::Course::Role::Participant.count }.by(1)
    end

    context 'for other event' do
      let(:event) do
        quest = course.questions.first
        other = Fabricate(:course, groups: [groups(:top_layer)])
        other.questions << Fabricate(:event_question, event: other)
        other.questions << Fabricate(:event_question, event: other, question: quest.question, choices: quest.choices)
        other
      end

      it 'updates answers for other event' do
        expect { subject.create_role }.to change { Event::Answer.count }.by(1)

        participation.event_id.should == event.id
      end

      it 'raises error on existing participation' do
        Fabricate(:event_participation, event: event, person: participation.person, application: Fabricate(:event_application))

        expect { subject.create_role }.to raise_error
      end
    end
  end


  describe '#remove_participant_role' do
    before do
      Fabricate(course.participant_type.name.to_sym, participation: participation)
    end

    it 'removes role for given application' do
      expect { subject.remove_role }.to change { Event::Course::Role::Participant.count }.by(-1)
    end

    it 'does not touch participation' do
      subject.remove_role
      Event::Participation.where(id: participation.id).exists?.should be_true
    end

    context 'roundtrip' do
      let(:event) { Fabricate(:course, groups: [groups(:top_layer)]) }

      it 'resets the event to priority_1' do
        participation.application.priority_1 = participation.event
        participation.application.save!
        subject.create_role
        participation.reload.event.should eq(event)
        subject.remove_role
        participation.reload.event.should eq(course)
      end
    end
  end
end
