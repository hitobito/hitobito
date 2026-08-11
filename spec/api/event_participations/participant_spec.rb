# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

# The participant of a readable participation is exposed even if the person may not be read
# otherwise. As this is a property of the relationship and not of a single endpoint, it is
# asserted through every endpoint leading to it.
describe "event_participations participant", type: :request do
  it_behaves_like "jsonapi authorized requests", required_scopes: [:event_participations] do
    subject(:make_request) do
      jsonapi_get "/api/event_participations", params: {include: "participant"}
    end

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

    def get_participations(includes: "participant", headers: {})
      jsonapi_get "/api/event_participations",
        params: {include: includes, filter: {event_id: event.id}}, headers: headers
      expect(response.status).to eq(200), response.body
    end

    describe "participant without any role" do
      it "is not readable through the people endpoint" do
        jsonapi_get "/api/people"
        expect(response.status).to eq(200), response.body
        expect(d.map(&:id)).not_to include(participant.id)
      end

      it "is exposed from the participations endpoint" do
        get_participations
        expect(included_people.pluck("id")).to include(participant.id.to_s)
      end

      it "is exposed from the events endpoint" do
        jsonapi_get "/api/events",
          params: {include: "participations.participant", filter: {id: event.id}}
        expect(response.status).to eq(200), response.body
        expect(included_people.pluck("id")).to include(participant.id.to_s)
      end

      it "is exposed without roles" do
        get_participations(includes: "participant.roles")

        person = included_people.find { |inc| inc["id"] == participant.id.to_s }
        expect(person["attributes"]["first_name"]).to eq participant.first_name
        expect(person["relationships"]["roles"]["data"]).to be_empty
      end

      it "does not cache the readable details across requests" do
        get_participations
        expect(included_additional_information).to eq "internal note"

        sign_in(Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)).person)
        get_participations
        expect(included_additional_information).to be_nil
      end

      context "with participation details permission" do
        it "is exposed with details" do
          get_participations

          person = included_people.find { |inc| inc["id"] == participant.id.to_s }
          expect(person["attributes"]["additional_information"]).to eq "internal note"
          expect(person["attributes"]).to have_key("birthday")
        end

        it "is exposed with all phone numbers" do
          public_number = Fabricate(:phone_number, contactable: participant, public: true)
          private_number = Fabricate(:phone_number, contactable: participant, public: false)

          get_participations(includes: "participant.phone_numbers")

          numbers = json["included"].to_a.select { |inc| inc["type"] == "phone_numbers" }
          expect(numbers.pluck("id"))
            .to match_array [public_number.id.to_s, private_number.id.to_s]
        end
      end

      context "with a read only token" do
        before { service_token.update!(permission: :layer_and_below_read) }

        it "is exposed with details" do
          get_participations

          person = included_people.find { |inc| inc["id"] == participant.id.to_s }
          expect(person["attributes"]["additional_information"]).to eq "internal note"
          expect(person["attributes"]).to have_key("birthday")
        end

        it "is exposed with all phone numbers" do
          public_number = Fabricate(:phone_number, contactable: participant, public: true)
          private_number = Fabricate(:phone_number, contactable: participant, public: false)

          get_participations(includes: "participant.phone_numbers")

          numbers = json["included"].to_a.select { |inc| inc["type"] == "phone_numbers" }
          expect(numbers.pluck("id"))
            .to match_array [public_number.id.to_s, private_number.id.to_s]
        end
      end

      context "as a person with layer_and_below_read" do
        let(:user) do
          Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)).person
        end

        before { sign_in(user) }

        it "is exposed without details" do
          get_participations

          person = included_people.find { |inc| inc["id"] == participant.id.to_s }
          expect(person["attributes"]["first_name"]).to eq participant.first_name
          expect(person["attributes"]).not_to have_key("additional_information")
          expect(person["attributes"]).not_to have_key("birthday")
        end

        it "is exposed with public phone numbers only" do
          public_number = Fabricate(:phone_number, contactable: participant, public: true)
          Fabricate(:phone_number, contactable: participant, public: false)

          get_participations(includes: "participant.phone_numbers")

          numbers = json["included"].to_a.select { |inc| inc["type"] == "phone_numbers" }
          expect(numbers.pluck("id")).to eq [public_number.id.to_s]
        end
      end
    end
  end
end
