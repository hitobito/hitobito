#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::PassesHelper do
  describe "#pass_card_bg_class" do
    it "returns nil for blank color" do
      expect(helper.pass_card_bg_class(nil)).to be_nil
      expect(helper.pass_card_bg_class("")).to be_nil
    end

    it "returns nil for invalid hex" do
      expect(helper.pass_card_bg_class("abc")).to be_nil
    end

    it "returns nil for light backgrounds" do
      expect(helper.pass_card_bg_class("#FFFFFF")).to be_nil
      expect(helper.pass_card_bg_class("#F0E68C")).to be_nil # khaki
    end

    it "returns 'pass-card--dark-bg' for dark backgrounds" do
      expect(helper.pass_card_bg_class("#000000")).to eq("pass-card--dark-bg")
      expect(helper.pass_card_bg_class("#1a1a2e")).to eq("pass-card--dark-bg")
      expect(helper.pass_card_bg_class("#003366")).to eq("pass-card--dark-bg")
    end

    it "works without hash prefix" do
      expect(helper.pass_card_bg_class("000000")).to eq("pass-card--dark-bg")
      expect(helper.pass_card_bg_class("FFFFFF")).to be_nil
    end
  end
end
