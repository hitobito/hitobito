# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
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
    participation = Fabricate(:event_participation, event: event)
    Fabricate(role.name.to_sym, participation: participation)
    participation
  end

  before { sign_in(people(:top_leader)) }

  it 'event kind has one qualification kind' do
    event.kind.qualification_kinds.should == [qualification_kinds(:sl)]
  end


  describe 'GET index' do
    before do
      participant_1
      participant_2
      leader_1

      get :index, group_id: group.id, event_id: event.id
    end

    context 'entries' do
      it { assigns(:participants).should have(2).items }
      it { assigns(:leaders).should have(1).items }
    end

  end

  describe 'PUT update' do
    subject { obtained_qualifications }

    context 'with one existing qualifications' do
      before do
        participant_1.person.qualifications.create!(qualification_kind_id: event.kind.qualification_kind_ids.first,
                                                    start_at: start_at)
      end

      context 'issued before qualification date' do
        let(:start_at) { event.qualification_date - 1.day }

        it 'issues qualification' do
          expect do
            put :update, group_id: group.id, event_id: event.id, id: participant_1.id, format: :js
          end.to change { Qualification.count }.by(1)
          should have(1).items
          should render_template('qualification')
        end
      end

      context 'issued on qualification date' do
        let(:start_at) { event.qualification_date }

        it 'keeps existing qualification' do
          expect do
            put :update, group_id: group.id, event_id: event.id, id: participant_1.id, format: :js
          end.not_to change { Qualification.count }
          should have(1).items
          should render_template('qualification')
        end
      end

    end

    context 'without existing qualifications' do
      before { put :update, group_id: group.id, event_id: event.id, id: participant_1.id, format: :js }

      it { should have(1).item }
      it { should render_template('qualification') }
    end

     context 'without existing qualifications for leader' do
       before { put :update, group_id: group.id, event_id: event.id, id: leader_1.id, format: :js }

       it { assigns(:nothing_changed).should be_true }
     end
  end


  describe 'DELETE destroy' do

    subject { obtained_qualifications }

    context 'without existing qualifications' do
      before do
        delete :destroy, group_id: group.id, event_id: event.id, id: participant_1.id, format: :js
      end

      it { should have(0).items }
      it { should render_template('qualification') }
    end

    context 'with one existing qualification' do
      before do
        participant_1.person.qualifications.create!(qualification_kind_id: event.kind.qualification_kind_ids.first,
                                                    start_at: event.qualification_date)
        delete :destroy, group_id: group.id, event_id: event.id, id: participant_1.id, format: :js
      end

      it { should have(0).items }
      it { should render_template('qualification') }
    end
  end

  def obtained_qualifications
    q = Event::Qualifier.for(participant_1)
    q.send(:obtained, q.send(:qualification_kinds))
  end
end
