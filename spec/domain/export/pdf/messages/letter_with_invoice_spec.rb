# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Messages::LetterWithInvoice do

  let(:letter) { messages(:with_invoice) }
  let(:recipients) { [people(:bottom_member)] }
  let(:options) { {} }

  let(:pdf) { described_class.new(letter, recipients, options) }
  subject { pdf }

  before { invoice_configs(:top_layer).update(payment_slip: :qr) }

  it "renders logo from settings and qr images" do
    expect_any_instance_of(Prawn::Document).to receive(:image).with(any_args).exactly(3).times
    subject.render
  end

  it "renders context via markup processor" do
    expect(Prawn::Markup::Processor).to receive_message_chain(:new, :parse)
    subject.render
  end

  it "does not raise for other payment slip" do
    invoice_configs(:top_layer).update(payment_slip: :ch_esr)
    subject.render
  end

  it "filename includes invoice model name" do
    expect(subject.filename).to eq "rechnung-mitgliedsbeitrag.pdf"
    expect(subject.filename(:preview)).to eq "preview-rechnung-mitgliedsbeitrag.pdf"
  end

  context "text" do
    subject { PDF::Inspector::Text.analyze(pdf.render) }

    it "renders text at positions" do
      pdf = described_class.new(letter, recipients).render
      expect(text_with_position).to match_array [
        [71, 687, "Bottom Member"],
        [71, 676, "Greatstreet 345"],
        [71, 666, "3456 Greattown"],
        [71, 531, "Mitgliedsbeitrag"],
        [71, 502, "Hallo"],
        [71, 481, "Dein "],
        [92, 481, "Mitgliedsbeitrag"],
        [161, 481, " ist fällig! "],
        [71, 460, "Bis bald"],
        [28, 290, "Empfangsschein"],
        [28, 265, "Konto / Zahlbar an"],
        [28, 254, "CH93 0076 2011 6238 5295 7"],
        [28, 242, "Hans Gerber"],
        [28, 187, "Zahlbar durch"],
        [28, 175, "Bottom Member"],
        [28, 164, "Greatstreet 345"],
        [28, 152, "3456 Greattown"],
        [28, 103, "Währung"],
        [85, 103, "Betrag"],
        [28, 92, "CHF"],
        [85, 92, "10.00"],
        [119, 53, "Annahmestelle"],
        [204, 290, "Zahlteil"],
        [204, 103, "Währung"],
        [261, 103, "Betrag"],
        [204, 92, "CHF"],
        [261, 92, "10.00"],
        [360, 292, "Konto / Zahlbar an"],
        [360, 280, "CH93 0076 2011 6238 5295 7"],
        [360, 269, "Hans Gerber"],
        [360, 214, "Zahlbar durch"],
        [360, 202, "Bottom Member"],
        [360, 191, "Greatstreet 345"],
        [360, 179, "3456 Greattown"]
      ]
    end

    context "dynamic" do
      let(:recipients) { [people(:bottom_member), people(:top_leader)] }

      context "stamped"do
        let(:options) { { stamped: true } }
        it "renders only some texts positions" do
          expect(text_with_position.count).to eq 43
          expect(text_with_position).to eq [
            [71, 687, "Bottom Member"],
            [71, 676, "Greatstreet 345"],
            [71, 666, "3456 Greattown"],
            [28, 290, "Empfangsschein"],
            [28, 265, "Konto / Zahlbar an"],
            [28, 254, "CH93 0076 2011 6238 5295 7"],
            [28, 242, "Hans Gerber"],
            [28, 187, "Zahlbar durch"],
            [28, 175, "Bottom Member"],
            [28, 164, "Greatstreet 345"],
            [28, 152, "3456 Greattown"],
            [28, 103, "Währung"],
            [85, 103, "Betrag"],
            [28, 92, "CHF"],
            [85, 92, "10.00"],
            [119, 53, "Annahmestelle"],
            [360, 292, "Konto / Zahlbar an"],
            [360, 280, "CH93 0076 2011 6238 5295 7"],
            [360, 269, "Hans Gerber"],
            [360, 214, "Zahlbar durch"],
            [360, 202, "Bottom Member"],
            [360, 191, "Greatstreet 345"],
            [360, 179, "3456 Greattown"],
            [71, 687, "Top Leader"],
            [71, 666, "Supertown"],
            [28, 290, "Empfangsschein"],
            [28, 265, "Konto / Zahlbar an"],
            [28, 254, "CH93 0076 2011 6238 5295 7"],
            [28, 242, "Hans Gerber"],
            [28, 187, "Zahlbar durch"],
            [28, 175, "Top Leader"],
            [28, 152, "Supertown"],
            [28, 103, "Währung"],
            [85, 103, "Betrag"],
            [28, 92, "CHF"],
            [85, 92, "10.00"],
            [119, 53, "Annahmestelle"],
            [360, 292, "Konto / Zahlbar an"],
            [360, 280, "CH93 0076 2011 6238 5295 7"],
            [360, 269, "Hans Gerber"],
            [360, 214, "Zahlbar durch"],
            [360, 202, "Top Leader"],
            [360, 179, "Supertown"]
          ]
        end
      end

      it "renders all texts at positions" do
        expect(text_with_position.count).to eq 65
        expect(text_with_position).to match_array [
          [71, 687, "Bottom Member"],
          [71, 676, "Greatstreet 345"],
          [71, 666, "3456 Greattown"],
          [71, 531, "Mitgliedsbeitrag"],
          [71, 502, "Hallo"],
          [71, 481, "Dein "],
          [92, 481, "Mitgliedsbeitrag"],
          [161, 481, " ist fällig! "],
          [71, 460, "Bis bald"],
          [28, 290, "Empfangsschein"],
          [28, 265, "Konto / Zahlbar an"],
          [28, 254, "CH93 0076 2011 6238 5295 7"],
          [28, 242, "Hans Gerber"],
          [28, 187, "Zahlbar durch"],
          [28, 175, "Bottom Member"],
          [28, 164, "Greatstreet 345"],
          [28, 152, "3456 Greattown"],
          [28, 103, "Währung"],
          [85, 103, "Betrag"],
          [28, 92, "CHF"],
          [85, 92, "10.00"],
          [119, 53, "Annahmestelle"],
          [204, 290, "Zahlteil"],
          [204, 103, "Währung"],
          [261, 103, "Betrag"],
          [204, 92, "CHF"],
          [261, 92, "10.00"],
          [360, 292, "Konto / Zahlbar an"],
          [360, 280, "CH93 0076 2011 6238 5295 7"],
          [360, 269, "Hans Gerber"],
          [360, 214, "Zahlbar durch"],
          [360, 202, "Bottom Member"],
          [360, 191, "Greatstreet 345"],
          [360, 179, "3456 Greattown"],
          [71, 687, "Top Leader"],
          [71, 666, "Supertown"],
          [71, 531, "Mitgliedsbeitrag"],
          [71, 502, "Hallo"],
          [71, 481, "Dein "],
          [92, 481, "Mitgliedsbeitrag"],
          [161, 481, " ist fällig! "],
          [71, 460, "Bis bald"],
          [28, 290, "Empfangsschein"],
          [28, 265, "Konto / Zahlbar an"],
          [28, 254, "CH93 0076 2011 6238 5295 7"],
          [28, 242, "Hans Gerber"],
          [28, 187, "Zahlbar durch"],
          [28, 175, "Top Leader"],
          [28, 152, "Supertown"],
          [28, 103, "Währung"],
          [85, 103, "Betrag"],
          [28, 92, "CHF"],
          [85, 92, "10.00"],
          [119, 53, "Annahmestelle"],
          [204, 290, "Zahlteil"],
          [204, 103, "Währung"],
          [261, 103, "Betrag"],
          [204, 92, "CHF"],
          [261, 92, "10.00"],
          [360, 292, "Konto / Zahlbar an"],
          [360, 280, "CH93 0076 2011 6238 5295 7"],
          [360, 269, "Hans Gerber"],
          [360, 214, "Zahlbar durch"],
          [360, 202, "Top Leader"],
          [360, 179, "Supertown"]
        ]
      end
    end
  end

  def text_with_position
    subject.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [subject.show_text[i]]
    end
  end
end
