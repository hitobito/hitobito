# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe GroupTypeResource, type: :resource do
  let(:data) { jsonapi_data.find { |entry| entry.id == group_type.sti_name } }

  describe "serialization" do
    context "of a layer" do
      let(:group_type) { Group::TopLayer }

      it "works" do
        render

        expect(data.jsonapi_type).to eq("group_types")
        expect(data.label).to eq(group_type.label)
        expect(data.label_plural).to eq(group_type.label_plural)
        expect(data.layer).to eq(true)
      end
    end

    context "of a group inside a layer" do
      let(:group_type) { Group::TopGroup }

      it "works" do
        render

        expect(data.layer).to eq(false)
      end
    end

    it "lists all group types of the instance" do
      render

      expect(jsonapi_data.collect(&:id)).to eq(Group.all_types.collect(&:sti_name))
    end

    it "pages when requested" do
      params[:page] = {size: 2, number: 2}
      render

      expect(jsonapi_data.collect(&:id)).to eq(Group.all_types[2, 2].collect(&:sti_name))
    end

    it "counts all group types in the total stat" do
      params[:stats] = {total: :count}
      render

      expect(json["meta"]["stats"]["total"]["count"]).to eq(Group.all_types.size)
    end

    it "rejects filtering" do
      params[:filter] = {label: "Top"}

      expect { render }.to raise_error(Graphiti::Errors::InvalidAttributeAccess)
    end

    it "is sorted along the group hierarchy by default" do
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

      expect(jsonapi_data.collect(&:id)).to eq(Group.all_types.collect(&:sti_name).sort.reverse)
    end

    it "rejects sorting by an unsortable attribute" do
      params[:sort] = "layer"

      expect { render }.to raise_error(Graphiti::Errors::InvalidAttributeAccess)
    end

    # The graphiti debugger, enabled in development, logs the id of every
    # returned record, so group types must be presented as records with an id.
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
  end

  describe "sideloading" do
    let(:group_type) { Group::TopLayer }

    def linked_ids(group_type, relationship)
      entry = json["data"].find { |data| data["id"] == group_type.sti_name }
      entry["relationships"][relationship.to_s]["data"].pluck("id")
    end

    it "includes the role types available for the group type" do
      params[:include] = "role_types"
      render

      expect(data.sideload(:role_types).collect(&:id))
        .to match_array(group_type.role_types.collect(&:sti_name))
      expect(data.sideload(:role_types).first.jsonapi_type).to eq("role_types")
    end

    it "includes the group types that may be created below the group type" do
      params[:include] = "possible_children"
      render

      expect(linked_ids(group_type, :possible_children))
        .to match_array(group_type.possible_children.collect(&:sti_name))
    end
  end
end
