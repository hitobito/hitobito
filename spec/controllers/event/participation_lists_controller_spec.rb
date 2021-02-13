#  Copyright (c) 2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ParticipationListsController do

  before { sign_in(people(:top_leader)) }

  let(:group)    { groups(:top_group) }
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
        post :create, params: { group_id: group, event_id: course, ids: person1.id, role: { type: Event::Role::Leader } }
      end.to raise_error(CanCan::AccessDenied)
        .and change(Event::Role::Leader, :count).by(0)
        .and change(Event::Participation, :count).by(0)
    end
  end

  context "POST create" do
    it "creates only one participation for one person" do
      expect do
        post :create, params: { group_id: group, event_id: course, ids: person1.id, role: { type: Event::Role::Leader } }
      end.to change(Event::Role::Leader, :count).by(1)
        .and change(Event::Participation, :count).by(1)

      expect(flash[:notice]).to include "Eine Person wurde erfolgreich zum Kurs 'Eventus' hinzugefügt"
    end

    it "may create multiple participations" do
      expect do
        post :create, params: { group_id: group, event_id: course, ids: [person2.id, person1.id].join(","), role: { type: Event::Role::Leader } }
      end.to change(Event::Role::Leader, :count).by(2)
        .and change(Event::Participation, :count).by(2)

      expect(flash[:notice]).to include "2 Personen wurden erfolgreich zum Kurs 'Eventus' hinzugefügt"
    end
  end

end
