# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceRuns::Receiver do
  describe "::load" do
    def load(array) = described_class.load(array.to_yaml)

    it "loads structured receiver" do
      expect(load([{id: 1, type: "Person", layer_group_id: 1}]))
        .to eq [described_class.new(id: 1, type: "Person", layer_group_id: 1)]
    end

    it "loads structured receiver with implicit type" do
      expect(load([{id: 1, layer_group_id: 1}])).to eq [described_class.new(id: 1, type: "Person", layer_group_id: 1)]
    end

    it "loads string receiver" do
      expect(load(["1"])).to eq [described_class.new(id: 1, type: "Person", layer_group_id: nil)]
    end

    it "loads integer receiver" do
      expect(load([1])).to eq [described_class.new(id: 1, type: "Person", layer_group_id: nil)]
    end

    it "loads multiple mixed receivers receiver" do
      list = [
        {id: 1, layer_group_id: 1},
        "2",
        3
      ]
      expect(load(list)).to eq [
        described_class.new(id: 1, type: "Person", layer_group_id: 1),
        described_class.new(id: 2, type: "Person", layer_group_id: nil),
        described_class.new(id: 3, type: "Person", layer_group_id: nil)
      ]
    end

    it "fails on unexpected data" do
      expect { load(["asdf"]) }.to raise_error(ArgumentError)
      expect { load([{a: 1}]) }.to raise_error(NoMatchingPatternError)
    end
  end
end
