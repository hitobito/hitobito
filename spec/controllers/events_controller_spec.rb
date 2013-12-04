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

    context 'GET new' do
      it 'loads sister groups' do
        sign_in(people(:top_leader))
        group3

        get :new, group_id: group.id, event: { type: 'Event' }

        assigns(:groups).should == [group3, group2]
      end

      it 'does not load deleted kinds' do
        sign_in(people(:top_leader))

        get :new, group_id: group.id, event: { type: 'Event::Course' }
        assigns(:kinds).should_not include event_kinds(:old)
      end
    end

    context 'POST create' do
      let(:date)  {{ label: 'foo', start_at_date: Date.today, finish_at_date: Date.today }}
      let(:question)  {{ question: 'foo?', choices: '1,2,3,4' }}

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
        should redirect_to(group_event_path(group, event))
        event.should be_persisted
        event.dates.should have(1).item
        event.dates.first.should be_persisted
        event.questions.should have(1).item
        event.questions.first.should be_persisted

        event.group_ids.should =~ [group.id, group2.id]
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
        assigns(:kinds).should_not include(course.reload.kind)
      end

      it 'edit does include deleted kind' do
        get :edit, group_id: group.id, id: course.id
        assigns(:kinds).should include(course.reload.kind)
      end

    end

    context 'groups' do
      before { group3.destroy }

      it 'new does not include delete' do
        get :new, group_id: group.id, event: { type: 'Event::Course' }
        assigns(:groups).should_not include(group3)
      end

      it 'edit does include delete' do
        get :edit, group_id: group.id, id: course.id
        assigns(:groups).should include(group3)
      end
    end
  end


end
