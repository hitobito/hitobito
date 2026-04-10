# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe ColorLuminance do
  describe ".calculate" do
    it "returns 0.0 for black" do
      expect(described_class.calculate("#000000")).to eq(0.0)
    end

    it "returns 1.0 for white" do
      expect(described_class.calculate("#FFFFFF")).to eq(1.0)
    end

    it "calculates luminance for red" do
      # WCAG 2.x: linearize(255) = 1.0, L = 0.2126 * 1.0
      expect(described_class.calculate("#FF0000")).to be_within(0.001).of(0.213)
    end

    it "calculates luminance for green" do
      # WCAG 2.x: linearize(255) = 1.0, L = 0.7152 * 1.0
      expect(described_class.calculate("#00FF00")).to be_within(0.001).of(0.715)
    end

    it "calculates luminance for blue" do
      # WCAG 2.x: linearize(255) = 1.0, L = 0.0722 * 1.0
      expect(described_class.calculate("#0000FF")).to be_within(0.001).of(0.072)
    end

    it "calculates luminance for gray" do
      # WCAG 2.x: linearize(128) ~= 0.216, L = 0.216
      expect(described_class.calculate("#808080")).to be_within(0.001).of(0.216)
    end

    it "calculates luminance for dark blue" do
      # WCAG 2.x: 0.7152 * linearize(51) + 0.0722 * linearize(102)
      expect(described_class.calculate("#003366")).to be_within(0.001).of(0.033)
    end

    it "calculates luminance for khaki" do
      # WCAG 2.x: 0.2126 * linearize(240) + 0.7152 * linearize(230) + 0.0722 * linearize(140)
      expect(described_class.calculate("#F0E68C")).to be_within(0.001).of(0.770)
    end

    it "works without # prefix" do
      expect(described_class.calculate("FFFFFF")).to eq(1.0)
    end

    it "works with lowercase hex" do
      expect(described_class.calculate("#ffffff")).to eq(1.0)
    end

    it "returns nil for blank string" do
      expect(described_class.calculate("")).to be_nil
    end

    it "returns nil for nil" do
      expect(described_class.calculate(nil)).to be_nil
    end

    it "returns nil for invalid length" do
      expect(described_class.calculate("#FFF")).to be_nil
      expect(described_class.calculate("#FFFFFFF")).to be_nil
    end

    it "returns nil for non-hex characters" do
      expect(described_class.calculate("#GGGGGG")).to eq(0.0) # to_i(16) returns 0 for invalid
    end
  end

  describe ".light?" do
    it "returns true for white" do
      expect(described_class.light?("#FFFFFF")).to be true
    end

    it "returns false for black" do
      expect(described_class.light?("#000000")).to be false
    end

    it "returns true for khaki (light color)" do
      expect(described_class.light?("#F0E68C")).to be true
    end

    it "returns false for dark blue" do
      expect(described_class.light?("#003366")).to be false
    end

    it "returns true for luminance exactly at 0.5001" do
      # #BCBCBC has WCAG luminance ~0.503, just above threshold
      expect(described_class.light?("#BCBCBC")).to be true
    end

    it "returns false for luminance at 0.5" do
      # Need to find a color with exactly 0.5 luminance
      # 0.5 * 255 = 127.5, so we need: 0.299*R + 0.587*G + 0.114*B = 127.5
      # Using R=127, G=127, B=127 gives ~0.5
      expect(described_class.light?("#7F7F7F")).to be false
    end

    it "returns false for nil" do
      expect(described_class.light?(nil)).to be false
    end

    it "returns false for invalid color" do
      expect(described_class.light?("#FFF")).to be false
    end
  end

  describe ".dark?" do
    it "returns true for black" do
      expect(described_class.dark?("#000000")).to be true
    end

    it "returns false for white" do
      expect(described_class.dark?("#FFFFFF")).to be false
    end

    it "returns false for khaki (light color)" do
      expect(described_class.dark?("#F0E68C")).to be false
    end

    it "returns true for dark blue" do
      expect(described_class.dark?("#003366")).to be true
    end

    it "returns true for luminance at 0.5" do
      expect(described_class.dark?("#7F7F7F")).to be true
    end

    it "returns false for luminance above 0.5" do
      # #BCBCBC has WCAG luminance ~0.503, just above threshold
      expect(described_class.dark?("#BCBCBC")).to be false
    end

    it "returns false for nil" do
      expect(described_class.dark?(nil)).to be false
    end

    it "returns false for invalid color" do
      expect(described_class.dark?("#FFF")).to be false
    end
  end
end
