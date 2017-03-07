# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe EventsController do

  let(:group) { groups(:top_group) }
  let(:group2) { Fabricate(Group::TopGroup.name.to_sym, name: 'CCC', parent: groups(:top_layer)) }
  let(:group3) { Fabricate(Group::TopGroup.name.to_sym, name: 'AAA', parent: groups(:top_layer)) }

  context 'event_course' do

    before { group2 }

    context 'GET show' do

      it 'sets empty @user_participation' do
        sign_in(people(:top_leader))

        get :show, group_id: groups(:top_layer).id, id: events(:top_event)

        expect(assigns(:user_participation)).to be_nil
      end

      it 'sets  @user_participation' do
        p = Fabricate(:event_participation, event: events(:top_event), person: people(:top_leader))
        sign_in(people(:top_leader))

        get :show, group_id: groups(:top_layer).id, id: events(:top_event)

        expect(assigns(:user_participation)).to eq(p)
      end

    end

    context 'GET new' do
      it 'loads sister groups' do
        sign_in(people(:top_leader))
        group3

        get :new, group_id: group.id, event: { type: 'Event' }

        expect(assigns(:groups)).to eq([group3, group2])
      end

      it 'does not load deleted kinds' do
        sign_in(people(:top_leader))

        get :new, group_id: group.id, event: { type: 'Event::Course' }
        expect(assigns(:kinds)).not_to include event_kinds(:old)
      end
    end

    context 'POST create' do
      let(:date)  { { label: 'foo', start_at_date: Date.today, finish_at_date: Date.today } }
      let(:question)  { { question: 'foo?', choices: '1,2,3,4' } }

      it 'creates new event course with dates' do
        sign_in(people(:top_leader))

        post :create, event: {  group_ids: [group.id, group2.id],
                                name: 'foo',
                                kind_id: event_kinds(:slk).id,
                                dates_attributes: [date],
                                questions_attributes: [question],
                                contact_id: people(:top_leader).id,
                                type: 'Event::Course' },
                      group_id: group.id

        event = assigns(:event)
        is_expected.to redirect_to(group_event_path(group, event))
        expect(event).to be_persisted
        expect(event.dates.size).to eq(1)
        expect(event.dates.first).to be_persisted
        expect(event.questions.size).to eq(1)
        expect(event.questions.first).to be_persisted

        expect(event.group_ids).to match_array([group.id, group2.id])
      end

      it "does not create event course if the user hasn't permission" do
        user = Fabricate(Group::BottomGroup::Leader.name.to_s, group: groups(:bottom_group_one_one))
        sign_in(user.person)

        expect do
          post :create, event: {  group_id: group.id,
                                  name: 'foo',
                                  type: 'Event::Course' },
                        group_id: group.id
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'PUT update' do
      let(:group) { groups(:top_layer) }
      let(:event) { events(:top_event) }

      before { sign_in(people(:top_leader)) }

      it 'creates, updates and destroys dates' do
        d1 = event.dates.create!(label: 'Pre', start_at_date: '1.1.2014', finish_at_date: '3.1.2014')
        d2 = event.dates.create!(label: 'Main', start_at_date: '1.2.2014', finish_at_date: '7.2.2014')

        expect do
          put :update, group_id: group.id,
                       id: event.id,
                       event: { name: 'testevent',
                                dates_attributes: {
                                   d1.id.to_s => { id: d1.id,
                                                   label: 'Vorweek',
                                                   start_at_date: '3.1.2014',
                                                   finish_at_date: '4.1.2014' },
                                   d2.id.to_s => { id: d2.id, _destroy: true },
                                   '999' => { label: 'Nachweek',
                                              start_at_date: '3.2.2014',
                                              finish_at_date: '5.2.2014' } } }
          expect(assigns(:event)).to be_valid
        end.not_to change { Event::Date.count }

        expect(event.reload.name).to eq 'testevent'
        dates = event.dates.order(:start_at)
        expect(dates.size).to eq(3)
        first = dates.second
        expect(first.label).to eq 'Vorweek'
        expect(first.start_at_date).to eq Date.new(2014, 1, 3)
        expect(first.finish_at_date).to eq Date.new(2014, 1, 4)
        second = dates.third
        expect(second.label).to eq 'Nachweek'
        expect(second.start_at_date).to eq Date.new(2014, 2, 3)
        expect(second.finish_at_date).to eq Date.new(2014, 2, 5)
      end

      it 'creates, updates and destroys questions' do
        q1 = event.questions.create!(question: 'Who?')
        q2 = event.questions.create!(question: 'What?')

        expect do
          put :update, group_id: group.id,
                       id: event.id,
                       event: { name: 'testevent',
                                questions_attributes: {
                                   q1.id.to_s => { id: q1.id,
                                                   question: 'Whoo?' },
                                   q2.id.to_s => { id: q2.id, _destroy: true },
                                   '999' => { question: 'How much?',
                                              choices: '1,2,3' } } }
          expect(assigns(:event)).to be_valid
        end.not_to change { Event::Question.count }

        expect(event.reload.name).to eq 'testevent'
        questions = event.questions.order(:question)
        expect(questions.size).to eq(2)
        first = questions.first
        expect(first.question).to eq 'How much?'
        expect(first.choices).to eq '1,2,3'
        second = questions.second
        expect(second.question).to eq 'Whoo?'
      end
    end

  end

  context 'destroyed associations' do
    let(:course) { Fabricate(:course, groups: [group, group2, group3]) }

    before do
      course
      sign_in(people(:top_leader))
    end

    context 'kind' do
      before { course.kind.destroy }

      it 'new does not include delted kind' do
        get :new, group_id: group.id, event: { type: 'Event::Course' }
        expect(assigns(:kinds)).not_to include(course.reload.kind)
      end

      it 'edit does include deleted kind' do
        get :edit, group_id: group.id, id: course.id
        expect(assigns(:kinds)).to include(course.reload.kind)
      end

    end

    context 'groups' do
      before { group3.destroy }

      it 'new does not include delete' do
        get :new, group_id: group.id, event: { type: 'Event::Course' }
        expect(assigns(:groups)).not_to include(group3)
      end

      it 'edit does include delete' do
        get :edit, group_id: group.id, id: course.id
        expect(assigns(:groups)).to include(group3)
      end
    end
  end


end
