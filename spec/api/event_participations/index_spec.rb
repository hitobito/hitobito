# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

describe "event_participations#index", type: :request do
  it_behaves_like "jsonapi authorized requests", required_scopes: [:event_participations] do
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

    describe "filtering by participant id and type" do
      let(:participation) { event_participations(:top) }

      let(:params) {
        {
          "filter[participant_id]": participation.participant_id,
          "filter[participant_type]": "Person"
        }
      }

      it "works" do
        expect(Event::ParticipationResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(%w[event_participations])
        expect(d.map(&:id)).to match_array(participation.id)
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

    describe "participant without any role" do
      let(:event) { events(:top_course) }
      let(:participant) { Fabricate(:person, additional_information: "internal note") }
      let!(:participation) do
        Fabricate(:event_participation, event: event, participant: participant, active: true)
      end

      def included_people
        json["included"].to_a.select { |inc| inc["type"] == "people" }
      end

      def included_additional_information
        included_people.find { |inc| inc["id"] == participant.id.to_s }
          .dig("attributes", "additional_information")
      end

      it "is not readable through the people endpoint" do
        jsonapi_get "/api/people"
        expect(response.status).to eq(200), response.body
        expect(d.map(&:id)).not_to include(participant.id)
      end

      it "is exposed as participant from the participations endpoint" do
        jsonapi_get "/api/event_participations",
          params: {include: "participant", filter: {event_id: event.id}}
        expect(response.status).to eq(200), response.body
        expect(included_people.pluck("id")).to include(participant.id.to_s)
      end

      it "is exposed as participant from the events endpoint" do
        jsonapi_get "/api/events",
          params: {include: "participations.participant", filter: {id: event.id}}
        expect(response.status).to eq(200), response.body
        expect(included_people.pluck("id")).to include(participant.id.to_s)
      end

      it "is exposed without roles" do
        jsonapi_get "/api/event_participations",
          params: {include: "participant.roles", filter: {event_id: event.id}}
        expect(response.status).to eq(200), response.body

        person = included_people.find { |inc| inc["id"] == participant.id.to_s }
        expect(person["attributes"]["first_name"]).to eq participant.first_name
        expect(person["relationships"]["roles"]["data"]).to be_empty
      end

      it "does not cache the service token's permissions across requests" do
        read_only_token = service_token.dup
        read_only_token.update!(name: "ReadOnly", permission: :layer_and_below_read, token: nil)

        jsonapi_get "/api/event_participations",
          params: {include: "participant", filter: {event_id: event.id}}
        expect(response.status).to eq(200), response.body
        expect(included_additional_information).to eq "internal note"

        jsonapi_get "/api/event_participations",
          params: {include: "participant", filter: {event_id: event.id}},
          headers: {"X-TOKEN" => read_only_token.token}
        expect(response.status).to eq(200), response.body
        expect(included_additional_information).to be_nil
      end

      context "with participation details permission" do
        it "is exposed with details" do
          jsonapi_get "/api/event_participations",
            params: {include: "participant", filter: {event_id: event.id}}
          expect(response.status).to eq(200), response.body

          person = included_people.find { |inc| inc["id"] == participant.id.to_s }
          expect(person["attributes"]["additional_information"]).to eq "internal note"
          expect(person["attributes"]).to have_key("birthday")
        end

        it "is exposed with all phone numbers" do
          public_number = Fabricate(:phone_number, contactable: participant, public: true)
          private_number = Fabricate(:phone_number, contactable: participant, public: false)

          jsonapi_get "/api/event_participations",
            params: {include: "participant.phone_numbers", filter: {event_id: event.id}}
          expect(response.status).to eq(200), response.body

          numbers = json["included"].to_a.select { |inc| inc["type"] == "phone_numbers" }
          expect(numbers.pluck("id"))
            .to match_array [public_number.id.to_s, private_number.id.to_s]
        end
      end

      context "without participation details permission" do
        # layer_and_below_read grants :show on the participation, but not :show_details
        before { service_token.update!(permission: :layer_and_below_read) }

        it "is exposed without details" do
          jsonapi_get "/api/event_participations",
            params: {include: "participant", filter: {event_id: event.id}}
          expect(response.status).to eq(200), response.body

          person = included_people.find { |inc| inc["id"] == participant.id.to_s }
          expect(person["attributes"]["first_name"]).to eq participant.first_name
          expect(person["attributes"]).not_to have_key("additional_information")
          expect(person["attributes"]).not_to have_key("birthday")
        end

        it "is exposed with public phone numbers only" do
          public_number = Fabricate(:phone_number, contactable: participant, public: true)
          Fabricate(:phone_number, contactable: participant, public: false)

          jsonapi_get "/api/event_participations",
            params: {include: "participant.phone_numbers", filter: {event_id: event.id}}
          expect(response.status).to eq(200), response.body

          numbers = json["included"].to_a.select { |inc| inc["type"] == "phone_numbers" }
          expect(numbers.pluck("id")).to eq [public_number.id.to_s]
        end
      end
    end
  end
end
