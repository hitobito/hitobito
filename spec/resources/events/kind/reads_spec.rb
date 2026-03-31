# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Event::KindResource, type: :resource do
  let(:kind) { event_kinds(:slk) }

  before do
    params[:filter] = {id: {eq: kind.id}}
  end

  describe "serialization" do
    let(:serialized_attrs) do
      [
        :short_name,
        :label,
        :minimum_age,
        :general_information,
        :application_conditions,
        :created_at,
        :updated_at
      ]
    end

    it "works" do
      render
      data = jsonapi_data[0]

      expect(data.attributes.symbolize_keys.keys).to match_array [:id,
        :jsonapi_type] + serialized_attrs

      expect(data.id).to eq(kind.id)
      expect(data.jsonapi_type).to eq("event_kinds")
      expect(data.attributes["type"]).to be_blank
    end
  end

  describe "including" do
    it "may include kind_category" do
      category = Fabricate(:event_kind_category)
      kind.update!(kind_category: category)
      params[:include] = "kind_category"
      render
      category = d[0].sideload(:kind_category)
      expect(category).to be_present
    end
  end
end
