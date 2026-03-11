# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

RSpec.describe "events#index", type: :request do
  it_behaves_like "jsonapi authorized requests" do
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

      context "including participant" do
        let(:bottom_member) { people(:bottom_member) }
        let(:params) { {include: "participations.participant", filter: {id: event.id}} }

        it "can include person" do
          make_request
          expect(response.status).to eq(200), response.body
          expect(json["data"][0]["relationships"]["participations"]["data"].size).to eq(1)
          expect(json["included"][0]["relationships"]["participant"]["data"]["type"]).to eq "people"
          expect(json["included"][0]["relationships"]["participant"]["data"]["id"]).to eq bottom_member.id.to_s
          expect(json["included"].last["id"]).to eq bottom_member.id.to_s
        end

        it "can include guest" do
          guest = Fabricate(:event_guest, main_applicant: participation, first_name: "Guest1")
          Fabricate(:event_participation, event: participation.event, participant: guest, active: true)
          params[:filter] = {participations: {participant_type: "Event::Guest"}}
          make_request
          expect(response.status).to eq(200), response.body
          expect(json["data"][0]["relationships"]["participations"]["data"].size).to eq(1)
          expect(json["included"][0]["relationships"]["participant"]["data"]["type"]).to eq "event_guests"
          expect(json["included"][0]["relationships"]["participant"]["data"]["id"]).to eq guest.id.to_s
          expect(json["included"].last["id"]).to eq guest.id.to_s
        end

        it "may not see included person if token has no permission" do
          service_token.update(people: false)
          make_request
          expect(response.status).to eq(200), response.body
          expect(json["data"][0]["relationships"]["participations"]["data"].size).to eq(1)
          expect(json["included"][0]["relationships"]["participant"]["data"]).to be_nil
        end
      end
    end
  end
end
