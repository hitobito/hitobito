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

  subject { described_class.new(letter, recipients, options) }

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

  context 'text' do
    subject do
      pdf = described_class.new(letter, recipients).render
      PDF::Inspector::Text.analyze(pdf)
    end

    it 'renders text at positions' do
      text_with_position = subject.positions.each_with_index.collect do |p, i|
        p.collect(&:round) + [subject.show_text[i]]
      end
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
        [105, 49, 'Annahmestelle'],
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
  end
end

