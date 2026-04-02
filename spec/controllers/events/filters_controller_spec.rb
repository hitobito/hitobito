# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::FiltersController do
  render_views

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before do
    sign_in(user)
  end

  describe "GET #new" do
    it "renders filter form with selected leaders" do
      get :new, params: {
        group_id: group.id,
        type: "Event",
        year: 2025,
        filters: {
          leader: {ids: [people(:bottom_member).id], user: "1"}
        }
      }

      expect(response).to have_http_status(:ok)
      expect(dom).to have_selector("#generals.show")
      expect(dom).to have_no_selector("filters_state_states")
      expect(dom).to have_select("filters_leader_ids", selected: ["Bottom Member"])
      expect(dom).to have_checked_field("filters_leader_user")
    end
  end

  describe "POST #create" do
    before { Event::Course.possible_states = %w[created closed canceled] }
    after { Event::Course.possible_states = [] }

    it "redirects to list" do
      post :create,
        params: {
          group_id: group.id,
          type: "Event::Course",
          year: 2025,
          range: "group",
          filters: {state: {states: ["created", "closed"]}}
        }

      expect(response).to redirect_to(course_group_events_path(
        group,
        year: 2025,
        range: "group",
        filters: {state: {states: ["created", "closed"]}}
      ))
    end
  end
end
