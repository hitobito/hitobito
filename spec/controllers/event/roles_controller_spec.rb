# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

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

  context "GET new" do
    before { get :new, params: {group_id: group.id, event_id: course.id, event_role: {type: Event::Role::Leader.sti_name}} }

    it "builds participation without answers" do
      role = assigns(:role)
      participation = role.participation
      expect(participation.event_id).to eq(course.id)
      expect(participation.answers.size).to eq(0)
    end
  end

  context "POST create" do
    context "without participation" do
      it "creates role and participation" do
        post :create, params: {group_id: group.id, event_id: course.id, event_role: {type: Event::Role::Leader.sti_name, person_id: user.id}}

        role = assigns(:role)
        expect(role).to be_persisted
        expect(role).to be_kind_of(Event::Role::Leader)
        participation = role.participation
        expect(participation.event_id).to eq(course.id)
        expect(participation.person_id).to eq(user.id)
        expect(participation.reload.answers.size).to eq(2)
        expect(course.reload.applicant_count).to eq 0
        expect(course.teamer_count).to eq 1
        expect(course.participant_count).to eq 0
        expect(flash[:notice]).to eq "Rolle <i>Hauptleitung</i> für <i>Top Leader</i> wurde erfolgreich erstellt."
        is_expected.to redirect_to(edit_group_event_participation_path(group, course, participation))
      end

      it "creates person add request if required" do
        groups(:bottom_layer_two).update_column(:require_person_add_requests, true)
        user.roles.destroy_all
        Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one), person: user)
        Fabricate(Event::Role::Leader.name, participation: Fabricate(:event_participation, event: course, person: user))
        person = Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person

        post :create,
          params: {
            group_id: group.id,
            event_id: course.id,
            event_role: {type: Event::Role::Speaker.sti_name, person_id: person.id}
          }

        is_expected.to redirect_to(group_event_participations_path(group, course))
        expect(flash[:alert]).to match(/versendet/)
        expect(person.reload.event_participations.count).to eq(0)
        expect(person.add_requests.count).to eq(1)
      end

      it "creates roles and participation for user even if person add request required" do
        groups(:top_layer).update_column(:require_person_add_requests, true)

        post :create,
          params: {
            group_id: group.id,
            event_id: course.id,
            event_role: {type: Event::Role::Speaker.sti_name, person_id: user.id}
          }

        role = assigns(:role)
        expect(role).to be_persisted
        expect(role).to be_kind_of(Event::Role::Speaker)

        expect(user.reload.event_participations.count).to eq(1)
        expect(user.add_requests.count).to eq(0)
      end
    end

    context "with existing participation" do
      it "creates role" do
        participation = Fabricate(:event_participation, event: course, person: user)
        Fabricate(Event::Role::Cook.name, participation: participation)
        expect do
          post :create, params: {group_id: group.id, event_id: course.id, event_role: {type: Event::Role::Leader.sti_name, person_id: user.id}}
        end.to change { Event::Participation.count }.by(0)

        role = assigns(:role)
        expect(role).to be_persisted
        expect(role).to be_kind_of(Event::Role::Leader)
        expect(role.participation).to eq(participation)
        expect(participation.answers.size).to eq(2)
        is_expected.to redirect_to(group_event_participations_path(group, course))
      end

      it "creates role if person add request" do
        groups(:bottom_layer_two).update_column(:require_person_add_requests, true)
        user.roles.destroy_all
        Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one), person: user)
        Fabricate(Event::Role::Leader.name, participation: Fabricate(:event_participation, event: course, person: user))
        person = Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person
        Fabricate(Event::Role::Cook.name, participation: Fabricate(:event_participation, event: course, person: person))

        post :create,
          params: {
            group_id: group.id,
            event_id: course.id,
            event_role: {type: Event::Role::Speaker.sti_name, person_id: person.id}
          }

        is_expected.to redirect_to(group_event_participations_path(group, course))
        expect(flash[:notice]).to match(/erstellt/)
        expect(person.reload.event_roles.count).to eq(2)
        expect(person.add_requests.count).to eq(0)
      end
    end
  end

  context "PUT update" do
    it "keeps type if not given" do
      role = event_roles(:top_leader)
      put :update,
        params: {
          group_id: group.id,
          event_id: course.id,
          id: role.id,
          event_role: {label: "Foo"}
        }

      role = Event::Role.find(role.id)
      expect(role).to be_kind_of(Event::Role::Leader)
      expect(role.label).to eq "Foo"
      is_expected.to redirect_to(group_event_participation_path(group, course, role.participation_id))
    end

    it "may change type for teamers" do
      role = event_roles(:top_leader)
      put :update,
        params: {
          group_id: group.id,
          event_id: course.id,
          id: role.id,
          event_role: {type: Event::Role::Cook.sti_name}
        }

      role = Event::Role.find(role.id)
      expect(role).to be_kind_of(Event::Role::Cook)
      is_expected.to redirect_to(group_event_participation_path(group, course, role.participation_id))
    end

    it "may not change type for teamers to participant" do
      role = event_roles(:top_leader)
      put :update,
        params: {
          group_id: group.id,
          event_id: course.id,
          id: role.id,
          event_role: {type: Event::Course::Role::Participant.sti_name}
        }

      role = Event::Role.find(role.id)
      expect(role).to be_kind_of(Event::Role::Leader)
      is_expected.to redirect_to(group_event_participation_path(group, course, role.participation_id))
    end

    it "may not change type for participant to team" do
      role = Fabricate(Event::Course::Role::Participant.name.to_sym,
        participation: Fabricate(:event_participation, event: course))
      put :update,
        params: {
          group_id: group.id,
          event_id: course.id,
          id: role.id,
          event_role: {type: Event::Role::Cook.sti_name}
        }

      role = Event::Role.find(role.id)
      expect(role).to be_kind_of(Event::Course::Role::Participant)
      is_expected.to redirect_to(group_event_participation_path(group, course, role.participation_id))
    end
  end
end
