#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::PassesHelper do
  describe "#pass_template_partial" do
    let(:lookup) { double("LookupContext") }

    before { allow(helper).to receive(:lookup_context).and_return(lookup) }

    it "returns the default path without consulting lookup_context" do
      expect(lookup).not_to receive(:find_all)
      result = helper.pass_template_partial("default", "card_front")
      expect(result).to eq("passes/templates/default/card_front")
    end

    it "returns custom template path when the partial exists" do
      allow(lookup).to receive(:find_all)
        .with("passes/templates/sac/_card_front")
        .and_return([double("template")])

      result = helper.pass_template_partial("sac", "card_front")
      expect(result).to eq("passes/templates/sac/card_front")
    end

    it "falls back to default when custom partial is missing" do
      allow(lookup).to receive(:find_all)
        .with("passes/templates/sac/_card_back")
        .and_return([])

      result = helper.pass_template_partial("sac", "card_back")
      expect(result).to eq("passes/templates/default/card_back")
    end
  end

  describe "#pass_qr_code_svg" do
    let(:person) { people(:top_leader) }
    let(:definition) { Fabricate(:pass_definition) }
    let(:pass) { Pass.new(person: person, definition: definition) }

    it "returns an SVG element" do
      svg = helper.pass_qr_code_svg(pass)
      expect(svg).to include("<svg")
      expect(svg).to include("</svg>")
    end

    it "applies the default size of 120" do
      svg = helper.pass_qr_code_svg(pass)
      expect(svg).to include('width="120"')
      expect(svg).to include('height="120"')
    end

    it "accepts a custom size" do
      svg = helper.pass_qr_code_svg(pass, size: 200)
      expect(svg).to include('width="200"')
      expect(svg).to include('height="200"')
    end

    it "includes the QR SVG CSS class" do
      svg = helper.pass_qr_code_svg(pass)
      expect(svg).to include('class="pass-card__qr-svg"')
    end

    it "returns an html_safe string" do
      svg = helper.pass_qr_code_svg(pass)
      expect(svg).to be_html_safe
    end
  end

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
