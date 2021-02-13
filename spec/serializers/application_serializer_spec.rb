# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ApplicationSerializer do
  class TestPersonSerializer < ApplicationSerializer
    schema do
      json_api_properties

      map_properties :first_name, :last_name

      apply_extensions(:details)

      # entities with content appearing multiple times
      entity :primary_group, item.primary_group do |group, s|
        s.json_api_properties
        s.property :name, group.name
      end
      # additional property to test unify_linked_entries
      entity :default_group, item.primary_group do |group, s|
        s.json_api_properties
        s.property :name, group.name
      end

      # entity containing only id
      entities :roles, item.roles do |role, s|
        s.json_api_properties
      end

      template_link(:primary_group, "groups", "/groups/%7Bprimary_group%7D", returning: true)

      modification_properties
    end

    extension(:details) do
      map_properties :town
    end

    extension(:other) do
      map_properties :country
    end

    extension(:details) do
      map_properties :email
    end
  end

  let(:person) do
    p = people(:top_leader)
    p.update!(creator_id: p.id)
    p
  end

  let(:controller) { double().as_null_object }

  let(:serializer) { TestPersonSerializer.new(person, controller: controller) }
  let(:hash) { serializer.to_hash }

  subject { hash[:people].first }

  context "format" do
    it "contains plural main key with one entry" do
      expect(hash).to have_key(:people)
      expect(hash[:people].size).to eq(1)
    end
  end

  context "#extensions" do
    it "contains all extension properties" do
      is_expected.to have_key(:town)
      is_expected.to have_key(:email)
      is_expected.not_to have_key(:country)
    end
  end

  context "#json_api_properties" do
    it "contains id as string" do
      expect(subject[:id]).to eq(person.id.to_s)
    end

    it "contains plural type" do
      expect(subject[:type]).to eq("people")
    end
  end

  context "#modification_properties" do
    it "contains created_at and updated_at" do
      expect(subject[:created_at]).to be_kind_of(Time)
      expect(subject[:updated_at]).to be_kind_of(Time)
    end

    it "contains creator_id and updater_id" do
      expect(subject[:links][:creator]).to eq(person.id.to_s)
      expect(subject[:links][:updater]).to be_nil
    end

    it "contains links for creator and updater" do
      expect(hash[:links]["people.creator"]).to have_key(:href)
      expect(hash[:links]["people.creator"][:type]).to eq("people")
      expect(hash[:links]["people.updater"]).to have_key(:href)
      expect(hash[:links]["people.updater"][:type]).to eq("people")
    end
  end

  context "#template_link" do
    it "are added to top level links" do
      expect(hash[:links][:primary_group][:type]).to eq("groups")
      expect(hash[:links][:primary_group][:href]).to eq("/groups/{primary_group}")
      expect(hash[:links][:primary_group][:returning]).to eq(true)
    end
  end

  context "#unify_linked_entities" do
    context "with attributes" do
      it "contains linked entries only once" do
        expect(hash[:linked]["groups"].size).to eq(1)
      end

      it "contains link data" do
        group = hash[:linked]["groups"].first
        expect(group[:id]).to eq(person.primary_group_id.to_s)
        expect(group[:name]).to eq("TopGroup")
      end

      it "contains only ids in item links" do
        expect(subject[:links][:primary_group]).to eq(person.primary_group_id.to_s)
        expect(subject[:links][:default_group]).to eq(person.primary_group_id.to_s)
      end
    end

    context "without attributes" do
      it "contains only ids in item links" do
        expect(subject[:links][:roles]).to eq([person.roles.first.id.to_s])
      end

      it "does not contain linked entries" do
        expect(hash[:linked]).not_to have_key("roles")
      end
    end
  end
end
