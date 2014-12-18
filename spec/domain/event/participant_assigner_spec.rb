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

  let(:participation) do
    p = Fabricate(:event_participation, event: course, application: Fabricate(:event_application))
    Fabricate(course.participant_types.first.name.to_sym, participation: p)
    p
  end

  let(:event) { course }

  subject { Event::ParticipantAssigner.new(event, participation) }

  describe '#add_participant' do

    before do
      participation.active = false
      participation.init_answers
      participation.save!
    end

    it 'sets given participation active' do
      subject.add_participant
      participation.reload
      participation.should be_active
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
        expect { subject.add_participant }.to change { Event::Answer.count }.by(1)

        participation.event_id.should == event.id
      end

      it 'raises error on existing participation' do
        Fabricate(:event_participation, event: event, person: participation.person, application: Fabricate(:event_application))

        expect { subject.add_participant }.to raise_error
      end
    end
  end


  describe '#remove_participant' do
    before do
      participation.active = true
      participation.save!
    end

    it 'removes role for given application' do
      subject.remove_participant
      participation.reload
      participation.should_not be_active
    end

    it 'does not touch participation' do
      subject.remove_participant
      Event::Participation.where(id: participation.id).exists?.should be_true
    end

    context 'roundtrip' do
      let(:event) { Fabricate(:course, groups: [groups(:top_layer)]) }

      it 'resets the event to priority_1' do
        participation.application.priority_1 = participation.event
        participation.application.save!
        subject.add_participant
        participation.reload.event.should eq(event)
        subject.remove_participant
        participation.reload.event.should eq(course)
      end
    end
  end

  describe 'participation with different prios' do
    let(:event1) { events(:top_course) }
    let(:event2) { Event::Course.create!(name: 'Event 2', group_ids: event1.group_ids,
                                         dates: event1.dates, kind: event_kinds(:slk)) }
    let(:assigner1) { Event::ParticipantAssigner.new(event1, participation) }
    let(:assigner2) { Event::ParticipantAssigner.new(event2, participation) }

    let(:participation) do
      p = Fabricate(:event_participation, event: event1, active: false)
      p.create_application!(priority_1: event1, priority_2: event2)
      Fabricate(course.participant_types.first.name.to_sym, participation: p)
      p.save!
      p.reload
      p
    end

    describe '#createable?' do
      it 'is true for both when no role has been created' do
        assigner1.should be_createable
        assigner2.should be_createable
      end

      it 'is false for assigner2 when already assigned to event1' do
        assigner1.add_participant
        assigner2.should_not be_createable
      end

      it 'is false for assigner1 when already assigned to event2' do
        assigner2.add_participant
        assigner1.should_not be_createable
      end
    end

    describe 'event#applicant_count' do

      before do
        participation
        assert_applicant_count(1, 0)
      end

      it 'changes when participant role is created and destroyed in priority_2 event' do
        assigner2.add_participant
        assert_applicant_count(0, 1)

        assigner2.remove_participant
        assert_applicant_count(1, 0)
      end

      it 'does not change when participant role is created and destroyed in priority_1 event' do
        assigner1.add_participant
        assert_applicant_count(1, 0)

        assigner1.remove_participant
        assert_applicant_count(1, 0)
      end

      def assert_applicant_count(count1, count2)
        event1.reload.applicant_count.should eq count1
        event2.reload.applicant_count.should eq count2
      end

    end
  end
end
