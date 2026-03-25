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

    it "may include roles" do
      params[:include] = "roles"
      render
      leader = d[0].sideload(:roles)[0]
      expect(leader.type).to eq "Event::Role::Leader"
      expect(leader.jsonapi_type).to eq "event_roles"
    end
  end
end
