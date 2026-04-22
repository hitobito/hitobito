# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Group::Statistics::Registry do
  let(:layer) { groups(:top_layer) }
  let(:non_layer) { groups(:top_group) }

  let(:stat_a) do
    Class.new(Group::Statistics::Base) do
      self.key = :stat_a
    end
  end

  let(:stat_b) do
    Class.new(Group::Statistics::Base) do
      self.key = :stat_b
      self.layer_only = false
    end
  end

  around do |example|
    original = described_class.statistics.dup
    example.run
    described_class.statistics.replace(original)
  end

  describe ".register" do
    it "adds the statistic class" do
      described_class.register(stat_a)
      expect(described_class.statistics).to include(stat_a)
    end

    it "does not add the same class twice" do
      described_class.register(stat_a)
      described_class.register(stat_a)
      expect(described_class.statistics.count { |s| s == stat_a }).to eq 1
    end

    it "raises when key is missing" do
      invalid = Class.new do
        def self.available_for?(_group) = true
      end
      expect { described_class.register(invalid) }.to raise_error(/must define/)
    end

    it "raises when available_for? is not implemented" do
      invalid = Class.new do
        def self.key = :missing_available_for
      end
      expect { described_class.register(invalid) }.to raise_error(/must implement/)
    end
  end

  describe ".available_for" do
    before do
      described_class.register(stat_a, stat_b)
    end

    it "returns statistics available for a layer group" do
      result = described_class.available_for(layer)
      expect(result).to include(stat_a, stat_b)
    end

    it "excludes layer_only statistics for non-layer groups" do
      result = described_class.available_for(non_layer)
      expect(result).not_to include(stat_a)
      expect(result).to include(stat_b)
    end
  end

  describe ".find_by_key" do
    before { described_class.register(stat_a) }

    it "finds by symbol key" do
      expect(described_class.find_by_key(:stat_a)).to eq stat_a
    end

    it "finds by string key" do
      expect(described_class.find_by_key("stat_a")).to eq stat_a
    end

    it "returns nil for unknown key" do
      expect(described_class.find_by_key(:unknown)).to be_nil
    end
  end
end
