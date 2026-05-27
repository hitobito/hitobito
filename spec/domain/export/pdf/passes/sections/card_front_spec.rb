#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Passes::Sections::CardFront do
  include PdfHelpers

  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:pass_definition) do
    Fabricate(:pass_definition, owner: group, name: "Testausweis",
      background_color: "#0066CC", description: "Pass Beschreibung")
  end
  let!(:pass) { Fabricate(:pass, person: person, pass_definition: pass_definition) }
  let(:pass_decorator) { pass.decorate }

  let(:pdf_document) { Export::Pdf::Document.new(page_size: "A4", page_layout: :portrait, margin: 0) }
  let(:pdf) { pdf_document.pdf }

  let(:card_layout) do
    bounds = OpenStruct.new(width: 210.mm, top: 297.mm)
    Export::Pdf::Passes::Default::Layout.new(bounds)
  end

  subject { described_class.new(pdf, pass_decorator, card_layout) }

  before do
    person.update!(
      first_name: "Max",
      last_name: "Muster"
    )
  end

  describe "#render" do
    let(:rendered_pdf) do
      subject.render
      pdf.render
    end
    let(:analyzer) { PDF::Inspector::Text.analyze(rendered_pdf) }

    it "renders the pass title" do
      texts = analyzer.strings
      expect(texts).to include("Testausweis")
    end

    it "renders the member name" do
      texts = analyzer.strings
      expect(texts).to include("Max Muster")
    end

    it "renders the member number label" do
      texts = analyzer.strings
      expect(texts).to include(I18n.t("activerecord.attributes.pass.member_number").upcase)
    end

    context "with validity dates" do
      before do
        pass.update!(valid_from: Date.new(2026, 1, 1), valid_until: Date.new(2026, 12, 31))
      end

      it "renders valid_from date" do
        texts = analyzer.strings.join(" ")
        expect(texts).to match(/#{I18n.t("activerecord.attributes.pass.valid_from")}/)
      end

      it "renders valid_until date" do
        texts = analyzer.strings.join(" ")
        expect(texts).to match(/#{I18n.t("activerecord.attributes.pass.valid_until")}/)
      end
    end

    context "without valid_until (open-ended pass)" do
      before do
        pass.update!(valid_from: Date.new(2026, 1, 1), valid_until: nil)
      end

      it "renders valid_from" do
        texts = analyzer.strings.join(" ")
        expect(texts).to match(/#{I18n.t("activerecord.attributes.pass.valid_from")}/)
      end

      it "does not render valid_until" do
        texts = analyzer.strings.join(" ")
        expect(texts).not_to match(/#{I18n.t("activerecord.attributes.pass.valid_until")}/)
      end
    end

    context "with light background color" do
      before do
        pass_definition.update!(background_color: "#FFFFFF")
      end

      it "uses dark text colors" do
        expect(pass_decorator.text_colors[:text]).to eq("333333")
      end
    end

    context "with dark background color" do
      before do
        pass_definition.update!(background_color: "#000000")
      end

      it "uses light text colors" do
        expect(pass_decorator.text_colors[:text]).to eq("FFFFFF")
      end
    end
  end
end
