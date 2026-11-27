# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "rails_helper"

describe "event_registrations#create", type: :request do
  let(:event) { events(:top_event) }

  before do
    event.update_columns(external_applications: true, application_opening_at: nil,
      application_closing_at: nil)
    service_tokens(:permitted_top_layer_token)
      .update!(register_event_participations: true, permission: :layer_and_below_full)
  end

  it_behaves_like "jsonapi authorized requests", person: nil,
    required_scopes: [:register_event_participations] do
    let(:attributes) { {first_name: "Anna", last_name: "Muster", email: "anna@example.com"} }
    let(:payload) { {data: {type: "event_registrations", attributes:}} }

    subject(:make_request) do
      jsonapi_post "/api/events/#{event.id}/registrations", payload
    end

    it "registers a new person and answers only with the registration status" do
      question = Fabricate(:event_question, event:, choices: "Ja,Nein")
      attributes[:answers] = [{question_id: question.id, answer: 1}]

      expect { make_request }.to change { Person.count }.by(1)
        .and change { event.participations.count }.by(1)

      expect(response.status).to eq(201), response.body
      expect(json["data"]["type"]).to eq "event_registrations"
      expect(json["data"]["attributes"]).to eq("registration_status" => "participant")
      expect(json["data"]["id"]).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      expect(response.body).not_to include("anna")
      expect(response.media_type).to eq "application/vnd.api+json"
      person = Person.find_by(email: "anna@example.com")
      participation = event.participations.find_by(participant: person)
      expect(participation.answers.find_by(question:).answer).to eq "Nein"
    end

    it "answers the same way for an existing registration" do
      person = people(:bottom_member)
      Fabricate(:event_participation, event:, participant: person, active: true)
      attributes.merge!(email: person.email, first_name: person.first_name,
        last_name: person.last_name)

      expect { make_request }.not_to change { Event::Participation.count }
      expect(response.status).to eq(201), response.body
      expect(json["data"]["attributes"]).to eq("registration_status" => "participant")
    end

    it "points to invalid attributes" do
      attributes.delete(:last_name)
      make_request

      expect(response.status).to eq(422), response.body
      expect(json["errors"]).to include(include(
        "source" => {"pointer" => "/data/attributes/last_name"},
        "meta" => include("code" => "blank")
      ))
    end

    it "rejects registrations for closed events" do
      event.update_columns(external_applications: false)
      make_request

      expect(response.status).to eq(422), response.body
      expect(json["errors"]).to include(include("meta" => include("code" => "event_not_open")))
    end

    it "forbids registrations for events outside of the token's layers" do
      service_token.update!(layer_group_id: groups(:bottom_layer_one).id)
      make_request

      expect(response.status).to eq(403), response.body
    end

    it "returns not found for unknown events" do
      jsonapi_post "/api/events/0/registrations", payload

      expect(response.status).to eq(404), response.body
    end
  end
end
