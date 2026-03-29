# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

RSpec.describe "events#index", type: :request do
  it_behaves_like "jsonapi authorized requests", required_scopes: [:events] do
    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/events", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(EventResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(%w[events courses])
        expect(d.map(&:id)).to match_array(Event.pluck(:id))
      end
    end

    context "with kind_category_id filter" do
      let(:kind_category) { Event::KindCategory.create!(label: "Event") }
      let(:params) { {filter: {kind_category_id: kind_category.id}} }

      before { Event.first.kind.update!(kind_category: kind_category) }

      it "only fetches events with specified kind_category_id" do
        expect(EventResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:id)).to match_array([Event.first.id])
      end
    end

    context "including participations" do
      let(:event) { events(:top_course) }
      let(:participation) { event_participations(:top) }
      let(:params) { {include: "participations", filter: {id: event.id}} }

      it "includes participations" do
        make_request
        expect(response.status).to eq(200), response.body
        expect(json["data"][0]["relationships"]["participations"]["data"].size).to eq(1)
        expect(json["included"][0]["id"]).to eq participation.id.to_s
      end

      it "has empty participations data for include if token lacks permission" do
        service_token.update!(event_participations: false)
        make_request
        expect(response.status).to eq(200), response.body
        expect(json["data"][0]["relationships"]["participations"]["data"]).to be_empty
        expect(json).not_to have_key("included")
      end
    end

    context "including contact" do
      let(:event) { Event.first }
      let(:params) { {include: "leaders,contact"} }

      it "returns the event contact" do
        event.update_attribute(:contact_id, people(:bottom_member).id)

        make_request

        expect(response.status).to eq(200)
        data = json["data"]
        contact_id = data[0]["relationships"]["contact"]["data"]["id"]
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
          expect(data[0]["relationships"]["contact"]["data"]).to be_nil
          expect(json["included"]).to be_nil
        end
      end
    end
  end
end
