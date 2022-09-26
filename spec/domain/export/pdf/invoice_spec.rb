# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'


describe Export::Pdf::Invoice do
  let(:invoice) { invoices(:invoice) }
  let(:sent)    { invoices(:sent) }

  context 'with articles' do
    subject do
      invoice = Invoice.new(
        sequence_number: '1-1',
        payment_slip: :qr,
        total: 1500,
        iban: 'CH93 0076 2011 6238 5295 7',
        reference: 'RF561A',
        esr_number: '00 00834 96356 70000 00000 00019',
        payee: "Acme Corp\nHallesche Str. 37\n3007 Hinterdupfing",
        recipient_address: "Max Mustermann\nMusterweg 2\n8000 Alt Tylerland",
        issued_at: Date.new(2022, 9, 26),
        due_at: Date.new(2022, 10, 26),
        creator: people(:top_leader),
        vat_number: 'CH 1234',
        sequence_number: '1-10',
        group: groups(:top_layer)
      )
      pdf = described_class.render(invoice, payment_slip: true, articles: true)
      PDF::Inspector::Text.analyze(pdf)
    end

    it 'renders full invoice' do
      expect(text_with_position).to eq([
        [347, 687, "Rechnungsnummer:"],
        [457, 687, "1-10"],
        [347, 674, "Rechnungsdatum:"],
        [457, 674, "26.09.2022"],
        [347, 662, "Fällig bis:"],
        [457, 662, "26.10.2022"],
        [347, 649, "Rechnungssteller:"],
        [457, 649, "Top Leader"],
        [347, 637, "MwSt. Nummer:"],
        [457, 637, "CH 1234"],
        [57, 688, "Max Mustermann"],
        [57, 676, "Musterweg 2"],
        [57, 665, "8000 Alt Tylerland"],
        [57, 539, "Rechnungsartikel"],
        [363, 539, "Anzahl"],
        [419, 539, "Preis"],
        [464, 539, "Betrag"],
        [515, 539, "MwSt."],
        [420, 526, "Zwischenbetrag"],
        [505, 526, "0.00 CHF"],
        [420, 513, "MwSt."],
        [505, 513, "0.00 CHF"],
        [420, 496, "Gesamtbetrag"],
        [490, 496, "1'500.00 CHF"],
        [14, 276, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 239, "CH93 0076 2011 6238 5295 7"],
        [14, 228, "Acme Corp"],
        [14, 216, "Hallesche Str. 37"],
        [14, 205, "3007 Hinterdupfing"],
        [14, 173, "Zahlbar durch"],
        [14, 161, "Max Mustermann"],
        [14, 150, "Musterweg 2"],
        [14, 138, "8000 Alt Tylerland"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 78, "CHF"],
        [71, 78, "1 500.00"],
        [105, 39, "Annahmestelle"],
        [190, 276, "Zahlteil"],
        [190, 89, "Währung"],
        [247, 89, "Betrag"],
        [190, 78, "CHF"],
        [247, 78, "1 500.00"],
        [346, 278, "Konto / Zahlbar an"],
        [346, 266, "CH93 0076 2011 6238 5295 7"],
        [346, 255, "Acme Corp"],
        [346, 243, "Hallesche Str. 37"],
        [346, 232, "3007 Hinterdupfing"],
        [346, 211, "Referenznummer"],
        [346, 200, "00 00834 96356 70000 00000 00019"],
        [346, 178, "Zahlbar durch"],
        [346, 167, "Max Mustermann"],
        [346, 155, "Musterweg 2"],
        [346, 144, "8000 Alt Tylerland"]
      ])
    end
  end

  it 'renders invoice with articles and payment_slip' do
    described_class.render(invoice, articles: true, payment_slip: true)
  end

  it 'renders empty invoice articles' do
    described_class.render(invoice, articles: true)
  end

  it 'renders empty invoice articles' do
    described_class.render(invoice, articles: true)
  end

  it 'renders empty invoice payment slip if without codeline' do
    expect_any_instance_of(Invoice::PaymentSlip).not_to receive(:code_line)
    described_class.render(Invoice.new(esr_number: 1, participant_number: 1),  payment_slip: true )
  end

  context 'currency' do
    subject do
      pdf = described_class.render(invoice, articles: true)
      PDF::Inspector::Text.analyze(pdf).show_text.compact.join(' ')
    end

    it 'defaults to CHF' do
      expect(subject).to match 'Gesamtbetrag 5.35 CHF'
    end

    it 'is read from invoice' do
      invoice.update(currency: "EUR")
      expect(subject).to match 'Gesamtbetrag 5.35 EUR'
      expect(subject).not_to match 'CHF'
    end
  end

  it 'includes payment reminder title and text' do
    reminder = Fabricate(:payment_reminder, invoice: sent, due_at: sent.due_at + 10.days)
    pdf = described_class.render(sent, articles: true)
    text = PDF::Inspector::Text.analyze(pdf).show_text
    expect(text).to include "#{reminder.title} - #{sent.title}"
    expect(text).to include reminder.text
  end

  context 'address' do
    it 'address with 8 lines does not cause page break' do
      invoice.update(address: 1.upto(8).to_a.join("\n"))
      pdf = described_class.render(invoice, articles: true)
      expect(PDF::Inspector::Page.analyze(pdf).pages.size).to eq 1
    end

    it 'address with 9 lines causes page break' do
      invoice.update(address: 1.upto(9).to_a.join("\n"))
      pdf = described_class.render(invoice, articles: true)
      expect(PDF::Inspector::Page.analyze(pdf).pages.size).to eq 2
    end
  end

  context 'codeline' do
    let(:invoice) { Invoice.new(sequence_number: '1-2', participant_number: 1) }

    subject do
      pdf = described_class.render(invoice, payment_slip: true)
      PDF::Inspector::Text.analyze(pdf)
    end

    before do
      ['invoice_address',
       'account_number',
       'amount',
       'esr_number',
       'payment_purpose',
       'left_receiver_address',
       'right_receiver_address',
      ].each do  |method|
        allow_any_instance_of(Export::Pdf::Invoice::PaymentSlip).to receive(method.to_sym)
      end
    end

    it 'with ch_esr' do
      invoice.payment_slip = 'ch_esr'
      expect(subject.positions).to eq [[323.5819133858268, 44.532913385826845]]
      expect(subject.show_text.first).to eq '042>000000000000100000000000023+ 1>'
    end

    it "with ch_besr" do
      invoice.payment_slip = 'ch_besr'
      expect(subject.positions).to eq [[323.5819133858268, 44.532913385826845]]
      expect(subject.show_text.first).to eq '042>000000000000100000000000023+ 1>'
    end

    it "with ch_besr" do
      invoice.payment_slip = 'ch_besr'
      expect(subject.positions).to eq [[323.5819133858268, 44.532913385826845]]
      expect(subject.show_text.first).to eq '042>000000000000100000000000023+ 1>'
    end


    context 'fixutre' do
      let(:invoice) { invoices(:invoice) }

      it 'has code_line' do
        expect(subject.positions).to eq [[271.95971338582683, 44.532913385826845],
                                         [463.69931338582677, 44.532913385826845]]

        expect(subject.show_text.compact).to eq ['0100000005353>000037680338900000000000021+',
                                                 '376803389000004>']
      end
    end
  end

  context 'qrcode' do
    let(:invoice) do
      Invoice.new(
        sequence_number: '1-1',
        payment_slip: :qr,
        total: 1500,
        iban: 'CH93 0076 2011 6238 5295 7',
        reference: 'RF561A',
        esr_number: '00 00834 96356 70000 00000 00019',
        payee: "Acme Corp\nHallesche Str. 37\n3007 Hinterdupfing",
        recipient_address: "Max Mustermann\nMusterweg 2\n8000 Alt Tylerland"
      )
    end

    subject do
      pdf = described_class.render(invoice, payment_slip: true)
      PDF::Inspector::Text.analyze(pdf)
    end

    it 'renders qrcode' do
      expect(text_with_position).to eq [
        [14, 276, 'Empfangsschein'],
        [14, 251, 'Konto / Zahlbar an'],
        [14, 239, 'CH93 0076 2011 6238 5295 7'],
        [14, 228, 'Acme Corp'],
        [14, 216, 'Hallesche Str. 37'],
        [14, 205, '3007 Hinterdupfing'],
        [14, 173, 'Zahlbar durch'],
        [14, 161, 'Max Mustermann'],
        [14, 150, 'Musterweg 2'],
        [14, 138, '8000 Alt Tylerland'],
        [14, 89, 'Währung'],
        [71, 89, 'Betrag'],
        [14, 78, 'CHF'],
        [71, 78, '1 500.00'],
        [105, 39, 'Annahmestelle'],
        [190, 276, 'Zahlteil'],
        [190, 89, 'Währung'],
        [247, 89, 'Betrag'],
        [190, 78, 'CHF'],
        [247, 78, '1 500.00'],
        [346, 278, 'Konto / Zahlbar an'],
        [346, 266, 'CH93 0076 2011 6238 5295 7'],
        [346, 255, 'Acme Corp'],
        [346, 243, 'Hallesche Str. 37'],
        [346, 232, '3007 Hinterdupfing'],
        [346, 211, 'Referenznummer'],
        [346, 200, '00 00834 96356 70000 00000 00019'],
        [346, 178, 'Zahlbar durch'],
        [346, 167, 'Max Mustermann'],
        [346, 155, 'Musterweg 2'],
        [346, 144, '8000 Alt Tylerland']
      ]
    end

    it 'does not render blank amount' do
      invoice.total = 0
      expect(text_with_position).to eq [
        [14, 276, 'Empfangsschein'],
        [14, 251, 'Konto / Zahlbar an'],
        [14, 239, 'CH93 0076 2011 6238 5295 7'],
        [14, 228, 'Acme Corp'],
        [14, 216, 'Hallesche Str. 37'],
        [14, 205, '3007 Hinterdupfing'],
        [14, 173, 'Zahlbar durch'],
        [14, 161, 'Max Mustermann'],
        [14, 150, 'Musterweg 2'],
        [14, 138, '8000 Alt Tylerland'],
        [14, 89, 'Währung'],
        [71, 89, 'Betrag'],
        [14, 78, 'CHF'],
        [105, 39, 'Annahmestelle'],
        [190, 276, 'Zahlteil'],
        [190, 89, 'Währung'],
        [247, 89, 'Betrag'],
        [190, 78, 'CHF'],
        [346, 278, 'Konto / Zahlbar an'],
        [346, 266, 'CH93 0076 2011 6238 5295 7'],
        [346, 255, 'Acme Corp'],
        [346, 243, 'Hallesche Str. 37'],
        [346, 232, '3007 Hinterdupfing'],
        [346, 211, 'Referenznummer'],
        [346, 200, '00 00834 96356 70000 00000 00019'],
        [346, 178, 'Zahlbar durch'],
        [346, 167, 'Max Mustermann'],
        [346, 155, 'Musterweg 2'],
        [346, 144, '8000 Alt Tylerland']
      ]
    end

    it 'does not render receipt and payment amount if total is hidden' do
      invoice.hide_total = true
      expect(text_with_position).to eq [
        [14, 276, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 239, "CH93 0076 2011 6238 5295 7"],
        [14, 228, "Acme Corp"],
        [14, 216, "Hallesche Str. 37"],
        [14, 205, "3007 Hinterdupfing"],
        [14, 173, "Zahlbar durch"],
        [14, 161, "Max Mustermann"],
        [14, 150, "Musterweg 2"],
        [14, 138, "8000 Alt Tylerland"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 78, "CHF"],
        [105, 39, "Annahmestelle"],
        [190, 276, "Zahlteil"],
        [190, 89, "Währung"],
        [247, 89, "Betrag"],
        [190, 78, "CHF"],
        [346, 278, "Konto / Zahlbar an"],
        [346, 266, "CH93 0076 2011 6238 5295 7"],
        [346, 255, "Acme Corp"],
        [346, 243, "Hallesche Str. 37"],
        [346, 232, "3007 Hinterdupfing"],
        [346, 211, "Referenznummer"],
        [346, 200, "00 00834 96356 70000 00000 00019"],
        [346, 178, "Zahlbar durch"],
        [346, 167, "Max Mustermann"],
        [346, 155, "Musterweg 2"],
        [346, 144, "8000 Alt Tylerland"]
      ]
    end
  end

  private

  def text_with_position
    subject.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [subject.show_text[i]]
    end
  end
end
