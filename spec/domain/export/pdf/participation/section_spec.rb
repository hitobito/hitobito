# frozen_string_literal: true

#  Copyright (c) 2023-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Participation::Section do
  include PdfHelpers

  let(:pdf) { Prawn::Document.new(page_size: "A4", page_layout: :portrait, margin: 2.cm) }

  describe "#render_columns" do
    def render_columns
      described_class.new(pdf, nil).send(:render_columns, left, right)
      pdf.text "~~~END~~~"
    end

    context "high left low right" do
      let(:left) { -> { 3.times { pdf.text "high" } } }
      let(:right) { -> { pdf.text "low" } }

      it "renders correctly" do
        render_columns
        expect(text_with_position.pretty_inspect).to eq [
          [57, 777, "high"],
          [57, 763, "high"],
          [57, 749, "high"],
          [301, 777, "low"],
          [57, 725, "~~~END~~~"]
        ].pretty_inspect
      end
    end

    context "low left high right" do
      let(:left) { -> { pdf.text "low" } }
      let(:right) { -> { 3.times { pdf.text "high" } } }

      it "renders correctly" do
        render_columns
        expect(text_with_position.pretty_inspect).to eq [
          [57, 777, "low"],
          [301, 777, "high"],
          [301, 763, "high"],
          [301, 749, "high"],
          [57, 725, "~~~END~~~"]
        ].pretty_inspect
      end
    end
  end
end
