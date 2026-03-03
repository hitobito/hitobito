#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Concerns::GroupAddressLookup do
  let(:test_class) do
    Class.new do
      include Export::Pdf::Concerns::GroupAddressLookup
      public :group_address_parts
    end
  end

  subject { test_class.new }

  let(:group) { groups(:top_group) }
  let(:layer_group) { group.layer_group }

  describe "#group_address_parts" do
    context "when group has address and town" do
      before do
        group.update!(street: "Bahnhofstr.", housenumber: "1", zip_code: "3000", town: "Bern")
      end

      it "returns name, address and zip+town" do
        parts = subject.group_address_parts(group)
        expect(parts).to eq([group.name, "Bahnhofstr. 1", "3000 Bern"])
      end
    end

    context "when group has no address but layer group does" do
      before do
        group.update!(street: nil, town: nil)
        layer_group.update!(street: "Layerstr.", housenumber: "5", zip_code: "6000", town: "Luzern")
      end

      it "falls back to layer group" do
        parts = subject.group_address_parts(group)
        expect(parts).to eq([layer_group.name, "Layerstr. 5", "6000 Luzern"])
      end
    end

    context "when neither group nor layer group has address" do
      before do
        group.update!(street: nil, town: nil)
        layer_group.update!(street: nil, town: nil)
      end

      it "returns empty array" do
        expect(subject.group_address_parts(group)).to eq([])
      end
    end

    context "when group has address but no town" do
      before do
        group.update!(street: "Bahnhofstr.", housenumber: "1", town: nil)
      end

      it "returns empty array" do
        expect(subject.group_address_parts(group)).to eq([])
      end
    end

    context "when group has town but no address" do
      before do
        group.update!(street: nil, town: "Bern", zip_code: "3000")
      end

      it "returns empty array" do
        expect(subject.group_address_parts(group)).to eq([])
      end
    end

    context "when address fields contain only whitespace" do
      before do
        group.update!(street: "  ", town: "  ")
      end

      it "returns empty array" do
        expect(subject.group_address_parts(group)).to eq([])
      end
    end

    context "when address fields contain extra whitespace" do
      before do
        group.update!(street: "  Bahnhofstr.  ", housenumber: "1", zip_code: "3000", town: "  Bern  ")
      end

      it "squishes whitespace in parts" do
        parts = subject.group_address_parts(group)
        expect(parts).to eq([group.name, "Bahnhofstr. 1", "3000 Bern"])
      end
    end
  end
end
