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

  describe 'participation with different prios' do
    let(:event1) { events(:top_event) }
    let(:event2) { Event::Course.create!(name: 'Event 2', group_ids: event1.group_ids,
                                         dates: event1.dates, kind: event_kinds(:slk)) }
    let(:participation) { Fabricate(:event_participation, event: event1, active: false) }
    let(:assigner1) { Event::ParticipantAssigner.new(event1, participation) }
    let(:assigner2) { Event::ParticipantAssigner.new(event2, participation) }

    before do
      participation.create_application!(priority_1: event1, priority_2: event2)
      participation.save!
      participation.reload
    end

    describe '#createable?' do
      it 'is true for both when no role has been created' do
        assigner1.should be_createable
        assigner2.should be_createable
      end

      it 'is false for assigner2 when already assigned to event1' do
        assigner1.create_role
        assigner2.should_not be_createable
      end

      it 'is false for assigner1 when already assigned to event2' do
        assigner2.create_role
        assigner1.should_not be_createable
      end
    end

    describe 'event#representative_participant_count' do

      before do
        [event1,event2].each(&:refresh_representative_participant_count!)
        assert_representative_participant_count(1, 0)
      end

      it 'changes when participant role is created and destroyed in priority_2 event' do
        assigner2.create_role
        assert_representative_participant_count(0, 1)

        assigner2.remove_role
        assert_representative_participant_count(1, 0)
      end

      it 'does not change when participant role is created and destroyed in priority_1 event' do
        assigner1.create_role
        assert_representative_participant_count(1, 0)

        assigner1.remove_role
        assert_representative_participant_count(1, 0)
      end

      def assert_representative_participant_count(count1, count2)
        event1.reload.representative_participant_count.should eq count1
        event2.reload.representative_participant_count.should eq count2
      end

    end
  end
end
