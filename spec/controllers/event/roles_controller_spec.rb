# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::RolesController do

  let(:group) { groups(:top_layer) }

  let(:course) do
    course = Fabricate(:course, groups: [group])
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course
  end

  let(:user) { people(:top_leader) }

  before { sign_in(user) }

  context 'GET new' do
    before { get :new, group_id: group.id, event_id: course.id, event_role: { type: Event::Role::Leader.sti_name } }

    it 'builds participation with answers' do
      role = assigns(:role)
      participation = role.participation
      participation.event_id.should == course.id
      participation.answers.should have(2).items
    end

  end

  context 'POST create' do

    context 'without participation' do

     it 'creates role and participation' do
        post :create, group_id: group.id, event_id: course.id, event_role: { type: Event::Role::Leader.sti_name, person_id: user.id }

        role = assigns(:role)
        role.should be_persisted
        role.should be_kind_of(Event::Role::Leader)
        participation = role.participation
        participation.event_id.should == course.id
        participation.person_id.should == user.id
        participation.answers.should have(2).items
        flash[:notice].should eq 'Rolle <i>Hauptleitung</i> für <i>Top Leader</i> wurde erfolgreich erstellt.'
        should redirect_to(edit_group_event_participation_path(group, course, participation))
      end
    end

    context 'with existing participation' do
      let (:participation) { Fabricate(:event_participation, event: course, person: user) }
      before do
        role = Event::Role::Cook.new
        role.participation = participation
        role.save!
      end

      it 'creates role and participation' do
        expect do
          post :create, group_id: group.id, event_id: course.id, event_role: { type: Event::Role::Leader.sti_name, person_id: user.id }
        end.to change { Event::Participation.count }.by(0)

        role = assigns(:role)
        role.should be_persisted
        role.should be_kind_of(Event::Role::Leader)
        role.participation.should == participation
        participation.answers.should have(0).items # o items as we didn't create any in the before block
        should redirect_to(group_event_participations_path(group, course))
      end
    end

  end

  context 'PUT update' do
    it 'keeps type if not given' do
      role = event_roles(:top_leader)
      put :update,
          group_id: group.id,
          event_id: course.id,
          id: role.id,
          event_role: { label: 'Foo' }

      role = Event::Role.find(role.id)
      role.should be_kind_of(Event::Role::Leader)
      role.label.should eq 'Foo'
      should redirect_to(group_event_participation_path(group, course, role.participation_id))
    end

    it 'may change type for teamers' do
      role = event_roles(:top_leader)
      put :update,
          group_id: group.id,
          event_id: course.id,
          id: role.id,
          event_role: { type: Event::Role::Cook.sti_name }

      role = Event::Role.find(role.id)
      role.should be_kind_of(Event::Role::Cook)
      should redirect_to(group_event_participation_path(group, course, role.participation_id))
    end

    it 'may not change type for teamers to participant' do
      role = event_roles(:top_leader)
      put :update,
          group_id: group.id,
          event_id: course.id,
          id: role.id,
          event_role: { type: Event::Course::Role::Participant.sti_name }

      role = Event::Role.find(role.id)
      role.should be_kind_of(Event::Role::Leader)
      should redirect_to(group_event_participation_path(group, course, role.participation_id))
    end


    it 'may not change type for participant to team' do
      role = Fabricate(Event::Course::Role::Participant.name.to_sym,
                       participation: Fabricate(:event_participation, event: course))
      put :update,
          group_id: group.id,
          event_id: course.id,
          id: role.id,
          event_role: { type: Event::Role::Cook.sti_name }

      role = Event::Role.find(role.id)
      role.should be_kind_of(Event::Course::Role::Participant)
      should redirect_to(group_event_participation_path(group, course, role.participation_id))
    end
  end

end
