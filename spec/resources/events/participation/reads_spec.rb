# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Event::ParticipationResource, type: :resource do
  let(:participation) { event_participations(:top) }
  let(:event) { participation.event }

  describe "serialization" do
    let(:serialized_attrs) do
      [
        :event_id,
        :participant_id,
        :participant_type,
        :additional_information,
        :application_id,
        :active,
        :qualified,
        :created_at,
        :updated_at
      ]
    end

    it "works" do
      render
      data = jsonapi_data[0]

      expect(data.attributes.symbolize_keys.keys).to match_array [:id, :jsonapi_type] + serialized_attrs

      expect(data.id).to eq(participation.id)
      expect(data.jsonapi_type).to eq("event_participations")
    end
  end

  describe "including" do
    it "may include event" do
      params[:include] = "event"
      render
      event = d[0].sideload(:event)
      expect(event.name).to eq "Top Course"
    end

    describe "participant" do
      context "person" do
        it "may include person" do
          params[:include] = "participant"
          render
          person = d[0].sideload(:participant)
          expect(person.jsonapi_type).to eq "people"
          expect(person.attributes["first_name"]).to eq "Bottom"
        end

        it "may include additional_emails and phone_numbers" do
          2.times { Fabricate(:additional_email, contactable: people(:bottom_member)) }
          2.times { Fabricate(:phone_number, contactable: people(:bottom_member)) }
          params[:include] = "participant.additional_emails,participant.phone_numbers"
          render
          person = d[0].sideload(:participant)
          expect(person.relationships.keys).to eq %w[
            primary_group
            layer_group
            roles
            phone_numbers
            social_accounts
            additional_emails
          ]
          expect(person.sideload(:additional_emails)).to have(2).items
          expect(person.sideload(:phone_numbers)).to have(2).items
        end
      end

      context "guest" do
        let!(:guest) { Fabricate(:event_guest, main_applicant: participation, first_name: "Guest1") }

        before do
          Fabricate(:event_participation, event: participation.event, participant: guest, active: true)
          params[:filter] = {participant_type: "Event::Guest"}
        end

        it "may include guest" do
          params[:include] = "participant"
          render
          guest = d[0].sideload(:participant)
          expect(guest.jsonapi_type).to eq "event_guests"
          expect(guest.attributes["first_name"]).to eq "Guest1"
        end

        it "may include additional_emails and phone_numbers but not defined on guest" do
          Fabricate(:additional_email, contactable: guest)
          Fabricate(:phone_number, contactable: guest)
          params[:include] = "participant.additional_emails,participant.phone_numbers"
          render
          guest = d[0].sideload(:participant)
          expect(guest.relationships).to be_nil
        end
      end
    end
  end
end
