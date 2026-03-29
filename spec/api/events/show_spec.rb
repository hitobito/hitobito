# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

RSpec.describe "events#show", type: :request do
  it_behaves_like "jsonapi authorized requests", required_scopes: [:events] do
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
      let(:params) { {include: "leaders,contact"} }

      it "works" do
        expect(EventResource).to receive(:find).and_call_original
        make_request

        expect(response.status).to eq(200)
        data = json["data"]
        expect(data["type"]).to eq("courses")
        expect(data["id"]).to eq(event.id.to_s)
        expect(data["relationships"]["leaders"]["data"].size).to eq(1)
        leader_id = data["relationships"]["leaders"]["data"][0]["id"]
        leader = json["included"].first { |inc| inc["type"] == "person-name" && inc.id == leader_id }
        expect(leader["attributes"]["first_name"]).to eq("Bottom")
        expect(leader["attributes"]["last_name"]).to eq("Member")
      end

      it "returns the event contact" do
        event.update_attribute(:contact_id, people(:bottom_member).id)

        make_request

        expect(response.status).to eq(200)
        data = json["data"]
        contact_id = data["relationships"]["contact"]["data"]["id"]
        contact = json["included"].first { |inc| inc["type"] == "person" && inc.id == contact_id }
        expect(contact["attributes"]["first_name"]).to eq("Bottom")
        expect(contact["attributes"]["last_name"]).to eq("Member")
        expect(contact["attributes"]["email"]).to eq(people(:bottom_member).email)
      end

      describe "without people scope" do
        before { service_token.update!(people: false) }

        it "does not return the event contact" do
          event.update_attribute(:contact_id, people(:bottom_member).id)

          make_request

          expect(response.status).to eq(200)
          data = json["data"]
          expect(data["relationships"]["contact"]["data"]).to be_nil
          expect(json["included"]).to be_nil
        end
      end
    end
  end
end
