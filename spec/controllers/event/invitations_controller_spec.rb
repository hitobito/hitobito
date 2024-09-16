# frozen_string_literal: true

#  Copyright (c) 2021, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::InvitationsController do
  before { sign_in(people(:top_leader)) }

  test_groups = [:top_group, :top_layer]
  let(:course) { Fabricate(:course, groups: [group], priorization: true) }
  let(:bottom_member) { people(:bottom_member) }
  let(:invitation_params) {
    {person_id: bottom_member.id,
     participation_type: "Event::Role::Participant"}
  }

  test_groups.each do |symbol|
    context "POST create" do
      let(:group) { groups(symbol) }

      it "creates invitation" do
        expect do
          post :create, params: {group_id: group.id, event_id: course.id, event_invitation: invitation_params}
        end.to change { Event::Invitation.count }.by(1)

        expect(Event::Invitation.where(invitation_params)).to exist
      end

      it "redirects to index path" do
        post :create, params: {group_id: group.id, event_id: course.id, event_invitation: invitation_params}
        expect(response).to redirect_to(group_event_invitations_path(group, course))
      end

      it "adds notice flash" do
        post :create, params: {group_id: group.id, event_id: course.id, event_invitation: invitation_params}
        expect(flash[:notice]).to eq("Einladung für Bottom Member als Teilnehmer/-in wurde erstellt.")
      end
    end

    context "background job" do
      let(:group) { groups(symbol) }

      it "exports csv" do
        expect do
          get :index, params: {group_id: group.id, event_id: course.id}, format: :csv
          expect(flash[:notice]).to match(/Export wird im Hintergrund gestartet und nach Fertigstellung heruntergeladen./)
          expect(response).to redirect_to(returning: true)
        end.to change(Delayed::Job, :count).by(1)
      end
    end
  end
end
