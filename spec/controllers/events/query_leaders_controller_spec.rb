# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::QueryLeadersController do
  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }

  let(:old_leader) { Fabricate(:person, last_name: "Meier", first_name: "Hans") }
  let(:current_leader) { Fabricate(:person, last_name: "Meier", first_name: "Johanna", nickname: nil, town: "Bern") }
  let(:other_leader) { Fabricate(:person, last_name: "Müller", first_name: "Lou") }
  let(:other_layer_leader) { Fabricate(:person, last_name: "Meier", first_name: "Franziska") }

  before do
    p1 = Fabricate(:event_participation, event: events(:top_event), participant: current_leader)
    Event::Role::Leader.create!(participation: p1)
    p2 = Fabricate(:event_participation, event: events(:top_event), participant: other_leader)
    Event::Role::Leader.create!(participation: p2)

    old_event = Fabricate(:event, groups: [groups(:top_group)],
      dates: [Event::Date.new(start_at: Time.zone.local(2011, 5, 11))])
    p3 = Fabricate(:event_participation, event: old_event, participant: old_leader)
    Event::Role::Leader.create!(participation: p3)

    other_layer_event = Fabricate(:event, groups: [groups(:bottom_group_one_one)])
    p4 = Fabricate(:event_participation, event: other_layer_event, participant: other_layer_leader)
    Event::Role::Leader.create!(participation: p4)
  end

  before { sign_in(user) }

  describe "GET #index" do
    it "renders list" do
      get :index, params: {group_id: group.id, year: 2012, q: "Meie"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/"Johanna Meier"/) # does not containt town or birthyear
      expect(response.body).not_to match(/Lou/)
      expect(response.body).not_to match(/Hans/)
      expect(response.body).not_to match(/Franziska/)
    end
  end
end
