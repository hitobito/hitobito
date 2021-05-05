# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Pdf::Messages::LetterWithInvoice do

  let(:letter) { messages(:with_invoice) }
  let(:recipients) { [people(:bottom_member)] }
  let(:options) { {} }

  let(:pdf) { described_class.new(letter, recipients, options) }
  subject { pdf }

  before { invoice_configs(:top_layer).update(payment_slip: :qr) }

  it 'renders logo from settings and qr images' do
    expect_any_instance_of(Prawn::Document).to receive(:image).with(any_args).exactly(3).times
    subject.render
  end

  it 'renders context via markup processor' do
    expect(Prawn::Markup::Processor).to receive_message_chain(:new, :parse)
    subject.render
  end

  it 'does not raise for other payment slip' do
    invoice_configs(:top_layer).update(payment_slip: :ch_esr)
    subject.render
  end

  it 'filename includes invoice model name' do
    expect(subject.filename).to eq 'rechnung-mitgliedsbeitrag.pdf'
    expect(subject.filename(:preview)).to eq 'preview-rechnung-mitgliedsbeitrag.pdf'
  end

  context 'text' do
    subject { PDF::Inspector::Text.analyze(pdf.render) }

    it 'renders text at positions' do
      pdf = described_class.new(letter, recipients).render
      expect(text_with_position).to match_array [
        [57, 669, 'Bottom Member'],
        [57, 658, 'Greatstreet 345'],
        [57, 648, '3456 Greattown'],
        [57, 579, 'Hallo Bottom'],
        [57, 558, 'Dein '],
        [78, 558, 'Mitgliedsbeitrag'],
        [147, 558, ' ist fällig! '],
        [57, 537, 'Bis bald'],
        [14, 276, 'Empfangsschein'],
        [14, 251, 'Konto / Zahlbar an'],
        [14, 239, 'CH93 0076 2011 6238 5295 7'],
        [14, 228, 'Hans Gerber'],
        [14, 173, 'Zahlbar durch'],
        [14, 161, 'Bottom Member'],
        [14, 150, 'Greatstreet 345'],
        [14, 138, '3456 Greattown'],
        [14, 89, 'Währung'],
        [71, 89, 'Betrag'],
        [14, 78, 'CHF'],
        [71, 78, '10.00'],
        [105, 39, 'Annahmestelle'],
        [190, 276, 'Zahlteil'],
        [190, 89, 'Währung'],
        [247, 89, 'Betrag'],
        [190, 78, 'CHF'],
        [247, 78, '10.00'],
        [346, 278, 'Konto / Zahlbar an'],
        [346, 266, 'CH93 0076 2011 6238 5295 7'],
        [346, 255, 'Hans Gerber'],
        [346, 200, 'Zahlbar durch'],
        [346, 188, 'Bottom Member'],
        [346, 177, 'Greatstreet 345'],
        [346, 165, '3456 Greattown']
      ]
    end

    context "dynamic" do
      let(:recipients) { [people(:bottom_member), people(:top_leader)] }

      context "stamped"do
        let(:options) { { stamped: true } }
        it 'renders only some texts positions' do
          expect(text_with_position.count).to eq 53
          expect(text_with_position).to match_array [
            [57, 669, "Bottom Member"],
            [57, 658, "Greatstreet 345"],
            [57, 648, "3456 Greattown"],
            [57, 579, "Hallo Bottom"],
            [57, 558, "Dein "],
            [78, 558, "Mitgliedsbeitrag"],
            [147, 558, " ist fällig! "],
            [57, 537, "Bis bald"],
            [14, 276, "Empfangsschein"],
            [14, 251, "Konto / Zahlbar an"],
            [14, 239, "CH93 0076 2011 6238 5295 7"],
            [14, 228, "Hans Gerber"],
            [14, 173, "Zahlbar durch"],
            [14, 161, "Bottom Member"],
            [14, 150, "Greatstreet 345"],
            [14, 138, "3456 Greattown"],
            [14, 89, "Währung"],
            [71, 89, "Betrag"],
            [14, 78, "CHF"],
            [71, 78, "10.00"],
            [105, 39, "Annahmestelle"],
            [346, 278, "Konto / Zahlbar an"],
            [346, 266, "CH93 0076 2011 6238 5295 7"],
            [346, 255, "Hans Gerber"],
            [346, 200, "Zahlbar durch"],
            [346, 188, "Bottom Member"],
            [346, 177, "Greatstreet 345"],
            [346, 165, "3456 Greattown"],
            [57, 669, "Top Leader"],
            [57, 648, "Supertown"],
            [57, 579, "Hallo Top"],
            [57, 558, "Dein "],
            [78, 558, "Mitgliedsbeitrag"],
            [147, 558, " ist fällig! "],
            [57, 537, "Bis bald"],
            [14, 276, "Empfangsschein"],
            [14, 251, "Konto / Zahlbar an"],
            [14, 239, "CH93 0076 2011 6238 5295 7"],
            [14, 228, "Hans Gerber"],
            [14, 173, "Zahlbar durch"],
            [14, 161, "Top Leader"],
            [14, 138, "Supertown"],
            [14, 89, "Währung"],
            [71, 89, "Betrag"],
            [14, 78, "CHF"],
            [71, 78, "10.00"],
            [105, 39, "Annahmestelle"],
            [346, 278, "Konto / Zahlbar an"],
            [346, 266, "CH93 0076 2011 6238 5295 7"],
            [346, 255, "Hans Gerber"],
            [346, 200, "Zahlbar durch"],
            [346, 188, "Top Leader"],
            [346, 165, "Supertown"]
          ]
        end
      end

      it 'renders all texts at positions' do
        expect(text_with_position.count).to eq 63
        expect(text_with_position).to match_array [
          [57, 669, "Bottom Member"],
          [57, 658, "Greatstreet 345"],
          [57, 648, "3456 Greattown"],
          [57, 579, "Hallo Bottom"],
          [57, 558, "Dein "],
          [78, 558, "Mitgliedsbeitrag"],
          [147, 558, " ist fällig! "],
          [57, 537, "Bis bald"],
          [14, 276, "Empfangsschein"],
          [14, 251, "Konto / Zahlbar an"],
          [14, 239, "CH93 0076 2011 6238 5295 7"],
          [14, 228, "Hans Gerber"],
          [14, 173, "Zahlbar durch"],
          [14, 161, "Bottom Member"],
          [14, 150, "Greatstreet 345"],
          [14, 138, "3456 Greattown"],
          [14, 89, "Währung"],
          [71, 89, "Betrag"],
          [14, 78, "CHF"],
          [71, 78, "10.00"],
          [105, 39, "Annahmestelle"],
          [190, 276, "Zahlteil"],
          [190, 89, "Währung"],
          [247, 89, "Betrag"],
          [190, 78, "CHF"],
          [247, 78, "10.00"],
          [346, 278, "Konto / Zahlbar an"],
          [346, 266, "CH93 0076 2011 6238 5295 7"],
          [346, 255, "Hans Gerber"],
          [346, 200, "Zahlbar durch"],
          [346, 188, "Bottom Member"],
          [346, 177, "Greatstreet 345"],
          [346, 165, "3456 Greattown"],
          [57, 669, "Top Leader"],
          [57, 648, "Supertown"],
          [57, 579, "Hallo Top"],
          [57, 558, "Dein "],
          [78, 558, "Mitgliedsbeitrag"],
          [147, 558, " ist fällig! "],
          [57, 537, "Bis bald"],
          [14, 276, "Empfangsschein"],
          [14, 251, "Konto / Zahlbar an"],
          [14, 239, "CH93 0076 2011 6238 5295 7"],
          [14, 228, "Hans Gerber"],
          [14, 173, "Zahlbar durch"],
          [14, 161, "Top Leader"],
          [14, 138, "Supertown"],
          [14, 89, "Währung"],
          [71, 89, "Betrag"],
          [14, 78, "CHF"],
          [71, 78, "10.00"],
          [105, 39, "Annahmestelle"],
          [190, 276, "Zahlteil"],
          [190, 89, "Währung"],
          [247, 89, "Betrag"],
          [190, 78, "CHF"],
          [247, 78, "10.00"],
          [346, 278, "Konto / Zahlbar an"],
          [346, 266, "CH93 0076 2011 6238 5295 7"],
          [346, 255, "Hans Gerber"],
          [346, 200, "Zahlbar durch"],
          [346, 188, "Top Leader"],
          [346, 165, "Supertown"]
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
