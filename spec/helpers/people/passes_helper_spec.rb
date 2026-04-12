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
        .with("passes/templates/members/_card_front")
        .and_return([double("template")])

      result = helper.pass_template_partial("members", "card_front")
      expect(result).to eq("passes/templates/members/card_front")
    end

    it "falls back to default when custom partial is missing" do
      allow(lookup).to receive(:find_all)
        .with("passes/templates/members/_card_back")
        .and_return([])

      result = helper.pass_template_partial("members", "card_back")
      expect(result).to eq("passes/templates/default/card_back")
    end
  end

  describe "#pass_qr_code_svg" do
    let(:person) { people(:top_leader) }
    let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
    let(:pass) {
      Fabricate.build(:pass, person: person, pass_definition: definition, state: :eligible,
        valid_from: Date.current).decorate
    }

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
      expect(svg).to include('class="pass-card-qr-svg"')
    end

    it "returns an html_safe string" do
      svg = helper.pass_qr_code_svg(pass)
      expect(svg).to be_html_safe
    end
  end

  describe "#pass_card_style" do
    let(:person) { people(:top_leader) }
    let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
    let(:pass) {
      Fabricate.build(:pass, person: person, pass_definition: definition, state: :eligible,
        valid_from: Date.current).decorate
    }

    it "includes the background color" do
      allow(pass.definition).to receive(:background_color).and_return("#003366")
      expect(helper.pass_card_style(pass)).to include("background-color: #003366")
    end

    it "sets light text variables for dark backgrounds" do
      allow(pass.definition).to receive(:background_color).and_return("#000000")
      style = helper.pass_card_style(pass)
      expect(style).to include("--pass-text: #fff")
      expect(style).to include("--pass-text-muted: #ccc")
      expect(style).to include("--pass-text-label: #aaa")
    end

    it "sets dark text variables for light backgrounds" do
      allow(pass.definition).to receive(:background_color).and_return("#FFFFFF")
      style = helper.pass_card_style(pass)
      expect(style).to include("--pass-text: #333")
      expect(style).to include("--pass-text-muted: #666")
      expect(style).to include("--pass-text-label: #888")
    end
  end
end
