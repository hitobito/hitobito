#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Invoice do
  include PdfHelpers

  let(:invoice) { invoices(:invoice) }
  let(:sent) { invoices(:sent) }

  let(:pdf) { described_class.render(invoice, payment_slip: true, articles: true) }

  def build_invoice(attrs)
    Invoice.new(attrs.reverse_merge(group: groups(:top_layer)))
  end

  context "with articles" do
    let(:invoice) do
      build_invoice(
        payment_slip: :qr,
        total: 1500,
        iban: "CH93 0076 2011 6238 5295 7",
        reference: "RF561A",
        esr_number: "00 00834 96356 70000 00000 00019",
        payee: "Acme Corp\nHallesche Str. 37\n3007 Hinterdupfing",
        recipient_address: "Max Mustermann\nMusterweg 2\n8000 Alt Tylerland",
        issued_at: Date.new(2022, 9, 26),
        due_at: Date.new(2022, 10, 26),
        creator: people(:top_leader),
        vat_number: "CH 1234",
        sequence_number: "1-10",
        group: groups(:top_layer)
      )
    end

    subject do
      pdf = described_class.render(invoice, payment_slip: true, articles: true)
      PDF::Inspector::Text.analyze(pdf)
    end

    it "renders full invoice with vat" do
      invoice.invoice_items.build(name: "pens", unit_cost: 10, vat_rate: 10, count: 2)
      invoice_text = [
        [347, 685, "Rechnungsnummer:"],
        [453, 685, "1-10"],
        [347, 672, "Rechnungsdatum:"],
        [453, 672, "26.09.2022"],
        [347, 659, "Fällig bis:"],
        [453, 659, "26.10.2022"],
        [347, 646, "Rechnungssteller:"],
        [453, 646, "Top Leader"],
        [347, 632, "MwSt. Nummer:"],
        [453, 632, "CH 1234"],
        [57, 686, "Max Mustermann"],
        [57, 674, "Musterweg 2"],
        [57, 662, "8000 Alt Tylerland"],
        [57, 537, "Rechnungsartikel"],
        [362, 537, "Anzahl"],
        [419, 537, "Preis"],
        [462, 537, "Betrag"],
        [515, 537, "MwSt."],
        [57, 522, "pens"],
        [383, 522, "2"],
        [417, 522, "10.00"],
        [513, 522, "10.0 %"],
        [389, 507, "Zwischenbetrag"],
        [502, 507, "20.00 CHF"],
        [389, 492, "MwSt."],
        [506, 492, "2.00 CHF"],
        [389, 474, "Gesamtbetrag"],
        [490, 474, "1'500.00 CHF"],
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
      ]

      text_with_position.each_with_index do |l, i|
        expect(l).to eq(invoice_text[i])
      end
    end

    it "renders full invoice without vat" do
      invoice.invoice_items.build(name: "pens", unit_cost: 10, count: 2)
      invoice_text = [
        [347, 685, "Rechnungsnummer:"],
        [453, 685, "1-10"],
        [347, 672, "Rechnungsdatum:"],
        [453, 672, "26.09.2022"],
        [347, 659, "Fällig bis:"],
        [453, 659, "26.10.2022"],
        [347, 646, "Rechnungssteller:"],
        [453, 646, "Top Leader"],
        [347, 632, "MwSt. Nummer:"],
        [453, 632, "CH 1234"],
        [57, 686, "Max Mustermann"],
        [57, 674, "Musterweg 2"],
        [57, 662, "8000 Alt Tylerland"],
        [57, 537, "Rechnungsartikel"],
        [362, 537, "Anzahl"],
        [419, 537, "Preis"],
        [462, 537, "Betrag"],
        [515, 537, "MwSt."],
        [57, 522, "pens"],
        [383, 522, "2"],
        [417, 522, "10.00"],
        [389, 507, "Zwischenbetrag"],
        [502, 507, "20.00 CHF"],
        [389, 489, "Gesamtbetrag"],
        [490, 489, "1'500.00 CHF"],
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
      ]

      text_with_position.each_with_index do |l, i|
        expect(l).to eq(invoice_text[i])
      end
    end

    it "renders full invoice with payments" do
      invoice.invoice_items.build(name: "pens", unit_cost: 10, count: 2)
      invoice.payments.build(amount: 10, received_at: Time.zone.yesterday)
      invoice.payments.build(amount: 5, received_at: Time.zone.yesterday)
      invoice.recalculate

      invoice_text = [
        [347, 685, "Rechnungsnummer:"],
        [453, 685, "1-10"],
        [347, 672, "Rechnungsdatum:"],
        [453, 672, "26.09.2022"],
        [347, 659, "Fällig bis:"],
        [453, 659, "26.10.2022"],
        [347, 646, "Rechnungssteller:"],
        [453, 646, "Top Leader"],
        [347, 632, "MwSt. Nummer:"],
        [453, 632, "CH 1234"],
        [57, 686, "Max Mustermann"],
        [57, 674, "Musterweg 2"],
        [57, 662, "8000 Alt Tylerland"],
        [57, 537, "Rechnungsartikel"],
        [362, 537, "Anzahl"],
        [419, 537, "Preis"],
        [462, 537, "Betrag"],
        [515, 537, "MwSt."],
        [57, 522, "pens"],
        [383, 522, "2"],
        [417, 522, "10.00"],
        [467, 522, "20.00"],
        [400, 507, "Zwischenbetrag"],
        [502, 507, "20.00 CHF"],
        [400, 492, "Gesamtbetrag"],
        [502, 492, "20.00 CHF"],
        [400, 477, "Eingegangene Zahlung"],
        [502, 477, "10.00 CHF"],
        [400, 462, "Eingegangene Zahlung"],
        [506, 462, "5.00 CHF"],
        [400, 445, "Offener Betrag"],
        [501, 445, "20.00 CHF"],
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
        [71, 78, "20.00"],
        [105, 39, "Annahmestelle"],
        [190, 276, "Zahlteil"],
        [190, 89, "Währung"],
        [247, 89, "Betrag"],
        [190, 78, "CHF"],
        [247, 78, "20.00"],
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

      text_with_position.each_with_index do |l, i|
        expect(l).to eq(invoice_text[i])
      end
    end
  end

  it "renders invoice with articles and payment_slip" do
    described_class.render(invoice, articles: true, payment_slip: true)
  end

  it "renders empty invoice articles" do
    described_class.render(invoice, articles: true)
  end

  it "renders empty invoice articles" do
    described_class.render(invoice, articles: true)
  end

  it "renders empty invoice payment slip if without codeline" do
    expect_any_instance_of(Invoice::PaymentSlip).not_to receive(:code_line)
    described_class.render(
      build_invoice(esr_number: 1, participant_number: 1),
      payment_slip: true
    )
  end

  context "currency" do
    subject do
      PDF::Inspector::Text.analyze(pdf).show_text.compact.join(" ")
    end

    it "defaults to CHF" do
      expect(subject).to match "Gesamtbetrag 5.35 CHF"
    end

    it "is read from invoice" do
      invoice.update(currency: "EUR")
      expect(subject).to match "Gesamtbetrag 5.36 EUR"
      expect(subject).not_to match "CHF"
    end
  end

  it "includes payment reminder title and text" do
    reminder = Fabricate(:payment_reminder, invoice: sent, due_at: sent.due_at + 10.days)
    pdf = described_class.render(sent, articles: true)
    text = PDF::Inspector::Text.analyze(pdf).show_text
    expect(text).to include "#{reminder.title} - #{sent.title}"
    expect(text).to include reminder.text
  end

  context "address" do
    it "address with 8 lines does not cause page break" do
      invoice.update(address: 1.upto(8).to_a.join("\n"))
      pdf = described_class.render(invoice, articles: true)
      expect(PDF::Inspector::Page.analyze(pdf).pages.size).to eq 1
    end

    it "address with 9 lines causes page break" do
      invoice.update(address: 1.upto(10).to_a.join("\n"))
      pdf = described_class.render(invoice, articles: true)
      expect(PDF::Inspector::Page.analyze(pdf).pages.size).to eq 2
    end

    it "has a compatible encoding" do
      invoice.update(address: "My∙Address")
      expect { described_class.render(invoice, articles: true) }.not_to raise_error
    end
  end

  context "codeline" do
    let(:invoice) { build_invoice(sequence_number: "1-2", participant_number: 1) }
    let(:pdf) { described_class.render(invoice, payment_slip: true) }

    subject { PDF::Inspector::Text.analyze(pdf) }

    before do
      %w[invoice_address
        account_number
        amount
        esr_number
        payment_purpose
        left_receiver_address
        right_receiver_address].each do |method|
        allow_any_instance_of(Export::Pdf::Invoice::PaymentSlip).to receive(method.to_sym)
      end
    end

    it "with ch_esr" do
      invoice.payment_slip = "ch_esr"
      expect(subject.positions).to eq [[323.58191, 44.53291]]
      expect(subject.show_text.first).to eq "042>000000000000100000000000023+ 1>"
    end

    it "with ch_besr" do
      invoice.payment_slip = "ch_besr"
      expect(subject.positions).to eq [[323.58191, 44.53291]]
      expect(subject.show_text.first).to eq "042>000000000000100000000000023+ 1>"
    end

    it "with ch_besr" do
      invoice.payment_slip = "ch_besr"
      expect(subject.positions).to eq [[323.58191, 44.53291]]
      expect(subject.show_text.first).to eq "042>000000000000100000000000023+ 1>"
    end

    context "fixutre" do
      let(:invoice) { invoices(:invoice) }

      it "has code_line" do
        expect(subject.positions).to eq [[271.95971, 44.53291],
          [463.69931, 44.53291]]

        expect(subject.show_text.compact).to eq ["0100000005353>000037680338900000000000021+",
          "376803389000004>"]
      end
    end
  end

  context "qrcode" do
    let(:invoice) do
      build_invoice(
        sequence_number: "1-1",
        payment_slip: :qr,
        total: 1500,
        iban: "CH93 0076 2011 6238 5295 7",
        reference: "RF561A",
        esr_number: "00 00834 96356 70000 00000 00019",
        payee: "Acme Corp\nHallesche Str. 37\n3007 Hinterdupfing",
        recipient_address: "Max Mustermann\nMusterweg 2\n8000 Alt Tylerland"
      )
    end

    let(:pdf) { described_class.render(invoice, payment_slip: true) }

    subject { PDF::Inspector::Text.analyze(pdf) }

    it "renders qrcode" do
      invoice_text = [
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
      ]

      text_with_position.each_with_index do |l, i|
        expect(l).to eq(invoice_text[i])
      end
    end

    it "does not render blank amount" do
      invoice.total = 0
      invoice_text = [
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

      text_with_position.each_with_index do |l, i|
        expect(l).to eq(invoice_text[i])
      end
    end

    it "does not render receipt and payment amount if total is hidden" do
      invoice.hide_total = true
      invoice_text = [
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

      text_with_position.each_with_index do |l, i|
        expect(l).to eq(invoice_text[i])
      end
    end
  end

  context "logo" do
    context "when invoice_config has no logo" do
      before do
        expect(invoice.invoice_config.logo).not_to be_attached
      end

      %i[disabled left right].each do |position|
        it "with logo_position=#{position} it does not render logo" do
          invoice.invoice_config.update(logo_position: position)
          expect(image_positions).to be_empty
        end
      end
    end

    context "when invoice_config has a logo" do
      before do
        invoice.invoice_config.logo.attach fixture_file_upload("images/logo.png")
        expect(invoice.invoice_config.logo).to be_attached
      end

      it "with logo_position=disabled it does not render logo" do
        invoice.invoice_config.update(logo_position: :disabled)
        expect(image_positions).to be_empty
      end

      it "with logo_position=left it renders logo on the left" do
        invoice.invoice_config.update(logo_position: :left)
        expect(image_positions).to have(1).item
        expect(image_positions.first).to match(
          displayed_height: 900.0,
          displayed_width: 52_900.0,
          height: 30,
          width: 230,
          x: 56.69291,
          y: 755.19709
        )
      end

      it "with logo_position=right it renders logo on the right" do
        invoice.invoice_config.update(logo_position: :right)
        expect(image_positions).to have(1).item
        expect(image_positions.first).to match(
          displayed_height: 900.0,
          displayed_width: 52_900.0,
          height: 30,
          width: 230,
          x: 308.58709,
          y: 755.19709
        )
      end
    end
  end
end
