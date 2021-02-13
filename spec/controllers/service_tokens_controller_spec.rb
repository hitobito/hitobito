#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ServiceTokensController do
  before { sign_in(person) }

  context "authorization" do
    let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }
    let(:person) { role.person }

    it "may index when person has permission" do
      get :index, params: {group_id: role.group}
      expect(response).to be_successful
    end

    it "may not index when person has no permission on top group" do
      expect do
        get :index, params: {group_id: groups(:top_group).id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context "authorized" do
    let(:person) { people(:top_leader) }

    it "may update flags" do
      token = service_tokens(:rejected_top_group_token)

      patch :update, params: {group_id: token.layer.id, id: token.id, service_token: {
        people: true,
        people_below: true,
        groups: true,
        events: true,
        invoices: true,
        event_participations: true,
        mailing_lists: true
      }}
      expect(token.reload).to be_people
      expect(token.reload).to be_people_below
      expect(token.reload).to be_groups
      expect(token.reload).to be_events
      expect(token.reload).to be_invoices
      expect(token.reload).to be_event_participations
      expect(token.reload).to be_mailing_lists
    end
  end
end
