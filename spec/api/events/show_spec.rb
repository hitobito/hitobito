# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

RSpec.describe "events#show", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let(:event) { events(:top_event) }

    subject(:make_request) do
      jsonapi_get "/api/events/#{event.id}", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(EventResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200)
        expect(d.jsonapi_type).to eq("events")
        expect(d.id).to eq(event.id)
      end
    end

    describe "course" do
      let(:event) { events(:top_course) }
      let(:params) { {include: "leaders"} }

      it "works" do
        expect(EventResource).to receive(:find).and_call_original
        make_request

        expect(response.status).to eq(200)
        data = json["data"]
        expect(data["type"]).to eq("courses")
        expect(data["id"]).to eq(event.id.to_s)
        expect(data["relationships"]["leaders"]["data"].size).to eq(1)
        leader = json["included"].first
        expect(leader["type"]).to eq("person-name")
        expect(leader["id"]).to eq(people(:bottom_member).id.to_s)
      end
    end
  end
end
