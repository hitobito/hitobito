#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Passes::Default do
  include PdfHelpers

  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:pass_definition) do
    Fabricate(:pass_definition, owner: group, name: "Testausweis",
      background_color: "#0066CC", description: "Pass Beschreibung")
  end
  let!(:pass) { Fabricate(:pass, person: person, pass_definition: pass_definition) }

  subject { described_class.new(pass) }

  let(:rendered_pdf) { subject.render }
  let(:analyzer) { PDF::Inspector::Text.analyze(rendered_pdf) }
  let(:page_analysis) { PDF::Inspector::Page.analyze(rendered_pdf) }

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
    it "returns valid PDF data" do
      expect(rendered_pdf).to start_with("%PDF")
    end

    it "has exactly one page" do
      expect(page_analysis.pages.size).to eq(1)
    end
  end

  describe "#filename" do
    it "generates a parameterized filename" do
      expect(subject.filename).to eq("pass-testausweis-max_muster.pdf")
    end

    it "handles special characters in names" do
      person.update!(first_name: "René", last_name: "Müller")
      pass_definition.update!(name: "Spezial Ausweis")
      pass.reload
      pdf = described_class.new(pass)
      expect(pdf.filename).to eq("pass-spezial_ausweis-rene_mueller.pdf")
    end
  end

  describe "recipient address" do
    it "renders the person address" do
      texts = text_with_position(analyzer).map(&:last)
      expect(texts).to include(a_string_matching(/Max Muster/))
      expect(texts).to include(a_string_matching(/Hauptstrasse 42/))
      expect(texts).to include(a_string_matching(/3000 Bern/))
    end
  end

  describe "sender address" do
    context "when group has address and town" do
      before do
        group.update!(street: "Vereinsgasse", housenumber: "1", town: "Zürich", zip_code: "8000")
      end

      it "renders the sender address line" do
        texts = text_with_position(analyzer).map(&:last)
        expect(texts).to include(a_string_matching(/#{group.name}.*Vereinsgasse 1.*8000 Zürich/))
      end
    end

    context "when group has no address" do
      before { group.update!(street: nil, housenumber: nil, town: nil) }

      it "does not render a sender address" do
        texts = text_with_position(analyzer).map(&:last)
        expect(texts).not_to include(a_string_matching(/#{group.name}.*,/))
      end
    end

    context "when owner has no address but layer group does" do
      let(:sub_group) { groups(:top_group) }
      let(:pass_definition) do
        Fabricate(:pass_definition, owner: sub_group, name: "Testausweis",
          background_color: "#0066CC")
      end

      before do
        sub_group.update!(street: nil, housenumber: nil, town: nil)
        group.update!(street: "Layerstrasse", housenumber: "5", town: "Luzern", zip_code: "6000")
      end

      it "falls back to the layer group address" do
        texts = text_with_position(analyzer).map(&:last)
        expect(texts).to include(a_string_matching(/#{group.name}.*Layerstrasse 5.*6000 Luzern/))
      end
    end
  end

  describe "front card" do
    it "renders the pass definition name" do
      texts = text_with_position(analyzer).map(&:last)
      expect(texts).to include("Testausweis")
    end

    it "renders the member name" do
      texts = text_with_position(analyzer).map(&:last)
      expect(texts).to include(a_string_matching(/Max Muster/))
    end

    it "renders the member number label" do
      texts = text_with_position(analyzer).map(&:last)
      expect(texts).to include(I18n.t("activerecord.attributes.pass.member_number").upcase)
    end

    it "renders the member number value" do
      texts = text_with_position(analyzer).map(&:last)
      expect(texts).to include(person.id.to_s)
    end
  end

  describe "back card" do
    it "renders QR placeholder" do
      texts = text_with_position(analyzer).map(&:last)
      expect(texts).to include("QR")
    end

    it "renders the pass title repeated on back" do
      texts = text_with_position(analyzer).map(&:last)
      expect(texts).to include("TESTAUSWEIS")
    end

    it "renders the description when present" do
      texts = text_with_position(analyzer).map(&:last)
      expect(texts).to include("Pass Beschreibung")
    end

    it "skips description when blank" do
      pass_definition.update!(description: nil)
      pass.reload
      pdf = described_class.new(pass)
      text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")
      expect(text).not_to include("Pass Beschreibung")
    end
  end

  describe "validity dates" do
    let(:pass_definition) do
      Fabricate(:pass_definition, owner: group, name: "Testausweis", background_color: "#0066CC")
    end

    before do
      # Create a pass grant and role so the Pass PORO computes validity
      grant = Fabricate(:pass_grant, pass_definition: pass_definition, grantor: groups(:top_group))
      grant.role_types = [Group::TopGroup::Leader.sti_name]
    end

    it "renders valid_from when present" do
      texts = text_with_position(analyzer).map(&:last)
      # The valid_from is computed from person's role start_on;
      # top_leader has a Leader role, so the text should include the valid_from label
      expect(texts).to include(a_string_matching(/#{I18n.t("activerecord.attributes.pass.valid_from")}/))
    end
  end

  describe "adaptive text color" do
    context "with dark background" do
      let(:pass_definition) do
        Fabricate(:pass_definition, owner: group, name: "Testausweis",
          background_color: "#003366")
      end

      it "renders PDF without error" do
        expect { rendered_pdf }.not_to raise_error
      end
    end

    context "with light background" do
      let(:pass_definition) do
        Fabricate(:pass_definition, owner: group, name: "Testausweis",
          background_color: "#FFFFFF")
      end

      it "renders PDF without error" do
        expect { rendered_pdf }.not_to raise_error
      end
    end
  end

  describe "logo fallback" do
    context "when no group has a logo" do
      it "renders PDF without error" do
        expect { rendered_pdf }.not_to raise_error
      end
    end

    context "when group has a logo attached" do
      before do
        group.logo.attach(
          io: Rails.root.join("spec", "fixtures", "files", "images", "logo.png").open,
          filename: "logo.png",
          content_type: "image/png"
        )
      end

      it "renders PDF with the logo" do
        expect { rendered_pdf }.not_to raise_error
        expect(rendered_pdf.length).to be > 1000
      end
    end
  end

  describe "person photo" do
    context "when person has a photo attached" do
      before do
        person.picture.attach(
          io: Rails.root.join("spec", "fixtures", "files", "images", "logo.png").open,
          filename: "photo.png",
          content_type: "image/png"
        )
      end

      it "renders PDF with the photo" do
        expect { rendered_pdf }.not_to raise_error
        expect(rendered_pdf.length).to be > 1000
      end
    end

    context "when person has no photo" do
      it "renders PDF without error" do
        expect(person.picture.attached?).to be false
        expect { rendered_pdf }.not_to raise_error
      end
    end
  end

  describe "card layout" do
    let(:graphic_analysis) { PDF::Inspector::Graphics::Rectangle.analyze(rendered_pdf) }

    it "renders cards without error" do
      expect { rendered_pdf }.not_to raise_error
    end

    describe "ISO ID-1 dimensions" do
      it "uses correct card width constant" do
        expect(described_class::CARD_WIDTH).to eq(85.6.mm)
      end

      it "uses correct card height constant" do
        expect(described_class::CARD_HEIGHT).to eq(53.98.mm)
      end

      it "uses correct corner radius constant" do
        expect(described_class::CARD_RADIUS).to eq(3.mm)
      end
    end

    describe "side-by-side layout" do
      it "positions cards with no gap between them" do
        expect(described_class::CARD_GAP).to eq(0.mm)
      end

      it "renders both front and back cards" do
        expect { rendered_pdf }.not_to raise_error
        texts = analyzer.strings
        expect(texts).to include("Testausweis")
        expect(texts).to include("TESTAUSWEIS")
      end
    end

    describe "crop marks" do
      let(:line_analysis) { PDF::Inspector::Graphics::Line.analyze(rendered_pdf) }

      it "renders crop mark lines" do
        expect { rendered_pdf }.not_to raise_error
        expect(line_analysis.points).not_to be_empty
      end

      it "uses correct crop mark length constant" do
        expect(described_class::CROP_MARK_LENGTH).to eq(5.mm)
      end

      it "uses correct crop mark offset constant" do
        expect(described_class::CROP_MARK_OFFSET).to eq(2.mm)
      end
    end
  end
end
