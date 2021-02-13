# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ActsAsTaggableOn::Tag do

  let(:person) { people(:top_leader) }

  context "stripping" do
    it "strips whitespaces before validation" do
      person.tag_list.add(" loremipsum ")
      person.save!
      expect(person.reload.tag_list.first).to eq("loremipsum")
    end

    [{ input: "lorem:ipsum", output: "lorem:ipsum" },
     { input: "lorem: ipsum", output: "lorem:ipsum" },
     { input: "lorem : ipsum", output: "lorem:ipsum" },
     { input: " lorem:ipsum ", output: "lorem:ipsum" },
     { input: "lorem:  ipsum", output: "lorem:ipsum" }].each do |data|
      it "strips '#{data[:input]}' '#{data[:input]}'" do
        person.tag_list.add(data[:input])
        person.save!
        expect(person.reload.tag_list.first).to eq(data[:output])
      end
    end
  end

  describe "grouped_by_category scope" do
    before do
      person.tag_list.add("vegetable:potato", "pizza", "fruit:banana", "fruit:apple")
      person.save!
    end

    it "returns the tag objects in a hash grouped by :-prefix" do
      result = person.tags.grouped_by_category
      expect(result.length).to eq(3)
      expect(result.map(&:first)).to eq([:fruit, :vegetable, :other])
      expect(result.first.second.map(&:name)).to eq(%w(fruit:apple fruit:banana))
      expect(result.second.second.map(&:name)).to eq(%w(vegetable:potato))
      expect(result.third.second.map(&:name)).to eq(%w(pizza))
    end
  end

  describe "#category" do
    it "returns :other if tag has no category" do
      expect(ActsAsTaggableOn::Tag.new.category).to eq(:other)
      expect(ActsAsTaggableOn::Tag.new(name: "lorem").category).to eq(:other)
      expect(ActsAsTaggableOn::Tag.new(name: "lorem:").category).to eq(:other)
      expect(ActsAsTaggableOn::Tag.new(name: ":lorem").category).to eq(:other)
      expect(ActsAsTaggableOn::Tag.new(name: ":lorem:").category).to eq(:other)
    end

    it "returns :-prefix as category" do
      expect(ActsAsTaggableOn::Tag.new(name: "lorem:ipsum").category).to eq(:lorem)
      expect(ActsAsTaggableOn::Tag.new(name: "lorem: ipsum").category).to eq(:lorem)
      expect(ActsAsTaggableOn::Tag.new(name: "lorem : ipsum").category).to eq(:lorem)
      expect(ActsAsTaggableOn::Tag.new(name: "lorem:ipsum:dolor").category).to eq(:lorem)
    end
  end

  describe "#name_without_category" do
    it "returns name if tag has no category" do
      expect(ActsAsTaggableOn::Tag.new.category).to eq(:other)
      expect(ActsAsTaggableOn::Tag.new(name: "lorem").name_without_category).to eq("lorem")
      expect(ActsAsTaggableOn::Tag.new(name: "lorem:").name_without_category).to eq("lorem:")
      expect(ActsAsTaggableOn::Tag.new(name: ":lorem").name_without_category).to eq(":lorem")
      expect(ActsAsTaggableOn::Tag.new(name: ":lorem:").name_without_category).to eq(":lorem:")
    end

    it "returns value after :-prefix as name" do
      expect(ActsAsTaggableOn::Tag.new(name: "lorem:ipsum").name_without_category).to eq("ipsum")
      expect(ActsAsTaggableOn::Tag.new(name: "lorem: ipsum").name_without_category).to eq("ipsum")
      expect(ActsAsTaggableOn::Tag.new(name: "lorem : ipsum").name_without_category).to eq("ipsum")
      expect(ActsAsTaggableOn::Tag.new(name: "lorem:ipsum:dolor").name_without_category).to eq("ipsum:dolor")
    end
  end

end
