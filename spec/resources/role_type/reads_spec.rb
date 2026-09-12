# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe RoleTypeResource, type: :resource do
  describe "serialization" do
    let(:data) { jsonapi_data.find { |entry| entry.id == role_type.sti_name } }

    context "of a role type belonging to a single group type" do
      let(:role_type) { Group::TopGroup::Leader }

      it "works" do
        render

        expect(data.jsonapi_type).to eq("role_types")
        expect(data.label).to eq(role_type.label)
        expect(data.kind).to eq("member")
        expect(data.permissions).to match_array(%w[admin layer_and_below_full finance
          contact_data impersonation])
        expect(data.visible_from_above).to eq(true)
        expect(data.group_types).to eq([Group::TopGroup.sti_name])
      end
    end

    context "of a global role type" do
      let(:role_type) { Role::External }

      it "works" do
        render

        expect(data.kind).to eq("external")
        expect(data.visible_from_above).to eq(false)
        expect(data.permissions).to eq([])
        expect(data.group_types).to match_array(Group.all_types.collect(&:sti_name))
      end
    end

    it "lists all role types of the instance" do
      render

      expect(jsonapi_data.collect(&:id)).to eq(Role.all_types.collect(&:sti_name))
    end

    it "pages when requested" do
      params[:page] = {size: 2, number: 2}
      render

      expect(jsonapi_data.collect(&:id)).to eq(Role.all_types[2, 2].collect(&:sti_name))
    end

    it "counts all role types in the total stat" do
      params[:stats] = {total: :count}
      render

      expect(json["meta"]["stats"]["total"]["count"]).to eq(Role.all_types.size)
    end

    it "rejects filtering" do
      params[:filter] = {label: "Leader"}

      expect { render }.to raise_error(Graphiti::Errors::InvalidAttributeAccess)
    end

    it "is not sorted alphabetically by default" do
      render

      expect(jsonapi_data.collect(&:label)).not_to eq(jsonapi_data.collect(&:label).sort)
    end

    it "sorts by label" do
      params[:sort] = "label"
      render

      expect(jsonapi_data.collect(&:label)).to eq(jsonapi_data.collect(&:label).sort)
    end

    it "sorts by id descending" do
      params[:sort] = "-id"
      render

      expect(jsonapi_data.collect(&:id)).to eq(Role.all_types.collect(&:sti_name).sort.reverse)
    end

    # The graphiti debugger, enabled in development, logs the id of every
    # returned record, so role types must be presented as records with an id.
    context "with the graphiti debugger enabled" do
      around do |example|
        enabled = Graphiti::Debugger.enabled
        Graphiti::Debugger.enabled = true
        example.run
      ensure
        Graphiti::Debugger.enabled = enabled
        Graphiti::Debugger.chunks = []
      end

      it "renders" do
        expect { render }.not_to raise_error
      end
    end

    it "rejects sorting by an unsortable attribute" do
      params[:sort] = "kind"

      expect { render }.to raise_error(Graphiti::Errors::InvalidAttributeAccess)
    end
  end
end
