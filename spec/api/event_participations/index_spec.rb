# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

describe "event_participations#index", type: :request do
  it_behaves_like "jsonapi authorized requests", required_flags: [:event_participations] do
    subject(:make_request) do
      jsonapi_get "/api/event_participations", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(Event::ParticipationResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(%w[event_participations])
        expect(d.map(&:id)).to match_array(Event::Participation.pluck(:id))
      end
    end

    it "returns participations with roles" do
      jsonapi_get "/api/event_participations", params: {include: "roles"}
      expect(response.status).to eq(200), response.body
      expect(response_body.dig(:included, 0, :type)).to eq "event_roles"
    end

    it "returns empty list without roles if participation is not accessible" do
      service_token.update!(layer_group_id: groups(:bottom_layer_one).id)
      jsonapi_get "/api/event_participations", params: {include: "roles"}
      expect(response.status).to eq(200), response.body
      expect(response_body.dig(:included)).to be_nil
    end
  end
end
