# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JsonApi::RoleTypesController, type: [:request] do
  describe "GET #index" do
    it "lists all role types without authentication" do
      jsonapi_get "/api/role_types"

      expect(response).to have_http_status(200)

      data = JSON.parse(response.body)["data"]
      expect(data.pluck("id")).to eq(Role.all_types.collect(&:sti_name))

      leader = data.find { |entry| entry["id"] == Group::TopGroup::Leader.sti_name }
      expect(leader["type"]).to eq("role_types")
      expect(leader["attributes"]).to eq(
        "label" => Group::TopGroup::Leader.label,
        "kind" => "member",
        "permissions" => %w[admin finance layer_and_below_full contact_data impersonation],
        "visible_from_above" => true,
        "group_types" => [Group::TopGroup.sti_name]
      )
    end

    it "returns localized labels" do
      jsonapi_get "/api/role_types", params: {locale: :fr}

      leader = JSON.parse(response.body)["data"]
        .find { |entry| entry["id"] == Group::TopGroup::Leader.sti_name }
      expect(leader["attributes"]["label"])
        .to eq(I18n.with_locale(:fr) { Group::TopGroup::Leader.label })
    end
  end
end
