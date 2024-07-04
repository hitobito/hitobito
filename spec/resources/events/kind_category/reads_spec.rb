# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Event::KindCategoryResource, type: :resource do
  let!(:category) { Fabricate(:event_kind_category) }

  before do
    params[:filter] = {id: {eq: category.id}}
  end

  describe "serialization" do
    let(:serialized_attrs) do
      [
        :label
      ]
    end

    it "works" do
      render
      data = jsonapi_data[0]
      expect(data.attributes.symbolize_keys.keys).to match_array [:id,
        :jsonapi_type] + serialized_attrs

      expect(data.id).to eq(category.id)
      expect(data.jsonapi_type).to eq("event_kind_categories")
      expect(data.attributes["type"]).to be_blank
    end
  end
end
