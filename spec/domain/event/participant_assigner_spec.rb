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
      expect(participation).to be_active
    end

    context 'for other event' do
      let(:event) do
        quest = course.questions.first
        other = Fabricate(:course, groups: [groups(:top_layer)])
        other.questions << Fabricate(:event_question, event: other)
        other.questions << Fabricate(:event_question, event: other, question: quest.question, choices: quest.choices, multiple_choices: quest.multiple_choices)
        other
      end

      it 'updates participation' do
        subject.add_participant

        expect(participation.event_id).to eq(event.id)
      end

      it 'updates answers so that every question of the new course has an answer' do
        expect { subject.add_participant }.to change { Event::Answer.count }.by(1)

        expect(participation.answers.count).to eq(3)
        answered = participation.reload.answers.map {|answer| answer.question.id}
        event.questions.each do |question|
          expect(answered).to include(question.id)
        end
      end

      it 'raises error on existing participation' do
        Fabricate(:event_participation, event: event, person: participation.person, application: Fabricate(:event_application))

        expect { subject.add_participant }.to raise_error(ActiveRecord::RecordNotUnique)
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
      expect(participation).not_to be_active
    end

    it 'does not touch participation' do
      subject.remove_participant
      expect(Event::Participation.where(id: participation.id).exists?).to be_truthy
    end

    it 'works even when the course in priority_1 does not exist anymore' do
      participation.application.update_attribute('priority_1_id', '99999')
      subject.remove_participant
      participation.reload
      expect(participation).not_to be_active
      expect(Event::Participation.where(id: participation.id).exists?).to be_truthy
    end

    context 'roundtrip' do
      let(:event) { Fabricate(:course, groups: [groups(:top_layer)]) }

      it 'resets the event to priority_1' do
        participation.application.priority_1 = participation.event
        participation.application.save!
        subject.add_participant
        expect(participation.reload.event).to eq(event)
        subject.remove_participant
        expect(participation.reload.event).to eq(course)
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
        expect(assigner1).to be_createable
        expect(assigner2).to be_createable
      end

      it 'is false for assigner2 when already assigned to event1' do
        assigner1.add_participant
        expect(assigner2).not_to be_createable
      end

      it 'is false for assigner1 when already assigned to event2' do
        assigner2.add_participant
        expect(assigner1).not_to be_createable
      end

      context 'waiting list duplicate' do
        before do
          participation.application.update!(waiting_list: true, priority_2: nil)

          p = Fabricate(:event_participation, event: event2, person: participation.person,
                                              active: false)
          p.create_application!(priority_1: event2)
          Fabricate(course.participant_types.first.name.to_sym, participation: p)
          p.save!
          p.reload
          p
        end

        it 'is false for assigner2 when person on waiting list already applied' do
          # regression test for: https://github.com/hitobito/hitobito/issues/162
          expect(assigner2).not_to be_createable
        end
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
        expect(event1.reload.applicant_count).to eq count1
        expect(event2.reload.applicant_count).to eq count2
      end

    end
  end
end
