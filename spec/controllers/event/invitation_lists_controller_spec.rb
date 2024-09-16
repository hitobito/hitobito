#  Copyright (c) 2024, Cevi Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::InvitationListsController do
  before { sign_in(people(:top_leader)) }

  let(:group) { groups(:top_group) }
  let!(:person1) { Fabricate(Group::TopGroup::Member.name.to_sym, group: group).person }
  let!(:person2) { Fabricate(Group::TopGroup::Member.name.to_sym, group: group).person }

  let(:course) do
    course = Fabricate(:course, groups: [group])
    course.dates << Fabricate(:event_date, event: course, start_at: course.dates.first.start_at)
    course
  end

  context "authorization" do
    before do
      sign_in(people(:bottom_member))
    end

    it "POST create" do
      expect do
        post :create, params: {group_id: group, event_id: course, ids: person1.id, role: {type: Event::Role::Leader}}
      end.to raise_error(CanCan::AccessDenied)
        .and change(Event::Invitation, :count).by(0)
    end
  end

  context "POST create" do
    it "creates only one invitation for one person" do
      expect do
        post :create, params: {group_id: group, event_id: course, ids: person1.id, role: {type: Event::Role::Participant}}
      end.to change(Event::Role::Participant, :count).by(0)
        .and change(Event::Invitation, :count).by(1)

      expect(flash[:notice]).to include "Eine Person wurde erfolgreich zum Kurs 'Eventus' eingeladen"
    end

    it "may create multiple invitations" do
      expect do
        post :create, params: {group_id: group, event_id: course, ids: [person2.id, person1.id].join(","), role: {type: Event::Role::Participant}}
      end.to change(Event::Role::Participant, :count).by(0)
        .and change(Event::Invitation, :count).by(2)

      expect(flash[:notice]).to include "2 Personen wurden erfolgreich zum Kurs 'Eventus' eingeladen<br />Hinweis: Allfällig bestehende Einladungen wurden nicht aktualisiert."
    end
  end
end
