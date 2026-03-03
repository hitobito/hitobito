#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Passes::Sections::Address do
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
      last_name: "Muster",
      street: "Hauptstrasse",
      housenumber: "42",
      zip_code: "3000",
      town: "Bern"
    )
  end

  describe "#render" do
    let(:rendered_pdf) do
      subject.render
      pdf.render
    end
    let(:analyzer) { PDF::Inspector::Text.analyze(rendered_pdf) }

    it "renders the person address" do
      texts = analyzer.strings
      expect(texts).to include("Max Muster")
      expect(texts).to include("Hauptstrasse 42")
      expect(texts).to include("3000 Bern")
    end

    context "when group has address" do
      before do
        group.update!(street: "Bahnhofstr.", housenumber: "1", zip_code: "3000", town: "Bern")
      end

      it "renders sender address" do
        texts = analyzer.strings
        expect(texts).to include(a_string_matching(/#{group.name}/))
        expect(texts).to include(a_string_matching(/Bahnhofstr/))
      end
    end

    context "when group has no address but layer group does" do
      let(:layer_group) { groups(:top_layer) }

      before do
        group.update!(street: nil, town: nil)
        layer_group.update!(street: "Layerstr.", housenumber: "5", zip_code: "8000", town: "Zürich")
      end

      it "renders layer group address as sender" do
        texts = analyzer.strings
        expect(texts).to include(a_string_matching(/Layerstr/))
        expect(texts).to include(a_string_matching(/Zürich/))
      end
    end

    context "when no group has address" do
      before do
        group.update!(street: nil, town: nil)
      end

      it "renders only recipient address" do
        texts = analyzer.strings
        expect(texts).to include("Max Muster")
        expect(texts).not_to include(a_string_matching(/#{group.name}/))
      end
    end
  end
end
