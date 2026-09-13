# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JsonApi::GroupTypesController, type: [:request] do
  describe "GET #index" do
    it "lists all group types without authentication" do
      jsonapi_get "/api/group_types"

      expect(response).to have_http_status(200)

      data = JSON.parse(response.body)["data"]
      expect(data.pluck("id")).to eq(Group.all_types.collect(&:sti_name))

      top_group = data.find { |entry| entry["id"] == Group::TopGroup.sti_name }
      expect(top_group["type"]).to eq("group_types")
      expect(top_group["attributes"]).to eq(
        "label" => Group::TopGroup.label,
        "label_plural" => Group::TopGroup.label_plural,
        "layer" => false
      )
    end

    it "includes the role types of the group types" do
      jsonapi_get "/api/group_types", params: {include: "role_types"}

      expect(response).to have_http_status(200)

      json = JSON.parse(response.body)
      top_group = json["data"].find { |entry| entry["id"] == Group::TopGroup.sti_name }
      expect(top_group["relationships"]["role_types"]["data"].pluck("id"))
        .to match_array(Group::TopGroup.role_types.collect(&:sti_name))
      expect(json["included"].pluck("type").uniq).to eq(["role_types"])
    end

    it "returns localized labels" do
      jsonapi_get "/api/group_types", params: {locale: :fr}

      top_group = JSON.parse(response.body)["data"]
        .find { |entry| entry["id"] == Group::TopGroup.sti_name }
      expect(top_group["attributes"]["label"])
        .to eq(I18n.with_locale(:fr) { Group::TopGroup.label })
    end
  end
end
