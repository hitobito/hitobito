# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::QualificationsController do

  let(:event) do
    event = Fabricate(:course, kind: event_kinds(:slk))
    event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    event
  end

  let(:group) { event.groups.first }

  let(:participant_1)  { create_participation(Event::Course::Role::Participant) }
  let(:participant_2)  { create_participation(Event::Course::Role::Participant) }
  let(:leader_1)       { create_participation(Event::Role::Leader) }

  def create_participation(role)
    participation = Fabricate(:event_participation, event: event, active: true)
    Fabricate(role.name.to_sym, participation: participation)
    participation.reload
  end

  before { sign_in(people(:top_leader)) }

  before do
    participant_1
    participant_2
    leader_1
  end

  it 'event kind has one qualification kind' do
    expect(event.kind.qualification_kinds('qualification', 'participant')).to eq [qualification_kinds(:sl)]
  end


  describe 'GET index' do

    context 'entries' do
      before do
        get :index, params: { group_id: group.id, event_id: event.id }
      end

      it { expect(assigns(:participants).size).to eq(2) }
      it { expect(assigns(:leaders).size).to eq(1) }
    end

    context 'for regular event' do
      let(:event) { events(:top_event) }

      it 'is not possible' do
        expect do
          get :index, params: { group_id: group.id, event_id: event.id }
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe 'PUT update' do
    subject { obtained_qualifications }

    context 'adding' do
      context 'with one existing qualifications' do
        before do
          qualification_kind_id = event.kind.qualification_kinds('qualification', 'participant').first.id
          participant_1.person.qualifications.create!(qualification_kind_id: qualification_kind_id,
                                                      start_at: start_at)
        end

        context 'issued before qualification date' do
          let(:start_at) { event.qualification_date - 1.day }

          it 'issues qualification' do
            expect do
              put :update, params: { group_id: group.id, event_id: event.id, participation_ids: [participant_1.id.to_s] }
            end.to change { Qualification.count }.by(1)
            expect(subject.size).to eq(1)
          end
        end

        context 'issued on qualification date' do
          let(:start_at) { event.qualification_date }

          it 'keeps existing qualification' do
            expect do
              put :update, params: { group_id: group.id, event_id: event.id, participation_ids: [participant_1.id] }
            end.not_to change { Qualification.count }
            expect(subject.size).to eq(1)
          end
        end

      end

      context 'without existing qualifications for participant' do
        before { put :update, params: { group_id: group.id, event_id: event.id, participation_ids: [participant_1.id] } }

        it 'has 1 item' do
          expect(subject.size).to eq(1)
        end
      end

      context 'without existing qualifications for leader' do
        before { put :update, params: { group_id: group.id, event_id: event.id, participation_ids: [leader_1.id] } }

        it 'should obtain a qualification' do
          obtained = obtained_qualifications(leader_1)
          expect(obtained.size).to eq(1)
        end
      end

    end

    context 'removing' do

      context 'without existing qualifications' do
        before do
          put :update, params: { group_id: group.id, event_id: event.id }
        end

        it 'has no items' do
          expect(subject.size).to eq(0)
        end
      end

      context 'with one existing qualification' do
        before do
          qualification_kind_id = event.kind.qualification_kinds('qualification', 'participant').first.id
          participant_1.person.qualifications.create!(qualification_kind_id: qualification_kind_id,
                                                      start_at: event.qualification_date)
          put :update, params: { group_id: group.id, event_id: event.id, participation_ids: [] }
        end

        it 'has no items' do
          expect(subject.size).to eq(0)
        end
      end

    end
  end

  def obtained_qualifications(person = participant_1)
    q = Event::Qualifier.for(person)
    q.send(:obtained, q.send(:qualification_kinds))
  end

end
