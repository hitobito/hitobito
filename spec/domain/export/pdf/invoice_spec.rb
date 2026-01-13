#  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Invoice do
  include PdfHelpers

  let(:invoice) { invoices(:invoice) }
  let(:sent) { invoices(:sent) }
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_layer) }

  let(:pdf) { described_class.render(invoice, payment_slip: true, articles: true, reminders: false) }

  def build_invoice(attrs)
    Invoice.new(attrs.reverse_merge(group: group))
  end

  context "with articles" do
    let(:invoice) do
      build_invoice(
        payment_slip: :qr,
        total: 1500,
        iban: "CH93 0076 2011 6238 5295 7",
        reference: "RF561A",
        esr_number: "00 00834 96356 70000 00000 00019",
        payee_name: "Acme Corp",
        payee_street: "Hallesche Str.",
        payee_housenumber: "37",
        payee_zip_code: "3007",
        payee_town: "Hinterdupfing",
        recipient_name: "Max Mustermann",
        recipient_street: "Musterweg",
        recipient_housenumber: "2",
        recipient_zip_code: "8000",
        recipient_town: "Alt Tylerland",
        issued_at: Date.new(2022, 9, 26),
        due_at: Date.new(2022, 10, 26),
        creator: person,
        vat_number: "CH 1234",
        sequence_number: "1-10",
        group: group
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
        [14, 275, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Acme Corp"],
        [14, 225, "Hallesche Str. 37"],
        [14, 216, "3007 Hinterdupfing"],
        [14, 197, "Referenznummer"],
        [14, 189, "00 00834 96356 70000 00000 00019"],
        [14, 170, "Zahlbar durch"],
        [14, 161, "Max Mustermann"],
        [14, 152, "Musterweg 2"],
        [14, 144, "8000 Alt Tylerland"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 77, "CHF"],
        [71, 77, "1 500.00"],
        [105, 39, "Annahmestelle"],
        [190, 275, "Zahlteil"],
        [190, 88, "Währung"],
        [247, 88, "Betrag"],
        [190, 76, "CHF"],
        [247, 76, "1 500.00"],
        [346, 276, "Konto / Zahlbar an"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Acme Corp"],
        [346, 244, "Hallesche Str. 37"],
        [346, 233, "3007 Hinterdupfing"],
        [346, 212, "Referenznummer"],
        [346, 201, "00 00834 96356 70000 00000 00019"],
        [346, 180, "Zahlbar durch"],
        [346, 169, "Max Mustermann"],
        [346, 158, "Musterweg 2"],
        [346, 147, "8000 Alt Tylerland"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
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
        [412, 537, "Anzahl"],
        [469, 537, "Preis"],
        [512, 537, "Betrag"],
        [57, 522, "pens"],
        [433, 522, "2"],
        [467, 522, "10.00"],
        [389, 507, "Zwischenbetrag"],
        [502, 507, "20.00 CHF"],
        [389, 489, "Gesamtbetrag"],
        [490, 489, "1'500.00 CHF"],
        [14, 275, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Acme Corp"],
        [14, 225, "Hallesche Str. 37"],
        [14, 216, "3007 Hinterdupfing"],
        [14, 197, "Referenznummer"],
        [14, 189, "00 00834 96356 70000 00000 00019"],
        [14, 170, "Zahlbar durch"],
        [14, 161, "Max Mustermann"],
        [14, 152, "Musterweg 2"],
        [14, 144, "8000 Alt Tylerland"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 77, "CHF"],
        [71, 77, "1 500.00"],
        [105, 39, "Annahmestelle"],
        [190, 275, "Zahlteil"],
        [190, 88, "Währung"],
        [247, 88, "Betrag"],
        [190, 76, "CHF"],
        [247, 76, "1 500.00"],
        [346, 276, "Konto / Zahlbar an"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Acme Corp"],
        [346, 244, "Hallesche Str. 37"],
        [346, 233, "3007 Hinterdupfing"],
        [346, 212, "Referenznummer"],
        [346, 201, "00 00834 96356 70000 00000 00019"],
        [346, 180, "Zahlbar durch"],
        [346, 169, "Max Mustermann"],
        [346, 158, "Musterweg 2"],
        [346, 147, "8000 Alt Tylerland"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
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
        [412, 537, "Anzahl"],
        [469, 537, "Preis"],
        [512, 537, "Betrag"],
        [57, 522, "pens"],
        [433, 522, "2"],
        [467, 522, "10.00"],
        [517, 522, "20.00"],
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
        [14, 275, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Acme Corp"],
        [14, 225, "Hallesche Str. 37"],
        [14, 216, "3007 Hinterdupfing"],
        [14, 197, "Referenznummer"],
        [14, 189, "00 00834 96356 70000 00000 00019"],
        [14, 170, "Zahlbar durch"],
        [14, 161, "Max Mustermann"],
        [14, 152, "Musterweg 2"],
        [14, 144, "8000 Alt Tylerland"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 77, "CHF"],
        [71, 77, "20.00"],
        [105, 39, "Annahmestelle"],
        [190, 275, "Zahlteil"],
        [190, 88, "Währung"],
        [247, 88, "Betrag"],
        [190, 76, "CHF"],
        [247, 76, "20.00"],
        [346, 276, "Konto / Zahlbar an"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Acme Corp"],
        [346, 244, "Hallesche Str. 37"],
        [346, 233, "3007 Hinterdupfing"],
        [346, 212, "Referenznummer"],
        [346, 201, "00 00834 96356 70000 00000 00019"],
        [346, 180, "Zahlbar durch"],
        [346, 169, "Max Mustermann"],
        [346, 158, "Musterweg 2"],
        [346, 147, "8000 Alt Tylerland"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
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
        [412, 537, "Anzahl"],
        [469, 537, "Preis"],
        [512, 537, "Betrag"],
        [57, 522, "pens"],
        [433, 522, "2"],
        [467, 522, "10.00"],
        [389, 507, "Zwischenbetrag"],
        [502, 507, "20.00 CHF"],
        [389, 489, "Gesamtbetrag"],
        [490, 489, "1'500.00 CHF"],
        [14, 275, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Acme Corp"],
        [14, 225, "Hallesche Str. 37"],
        [14, 216, "3007 Hinterdupfing"],
        [14, 197, "Referenznummer"],
        [14, 189, "00 00834 96356 70000 00000 00019"],
        [14, 170, "Zahlbar durch"],
        [14, 161, "Max Mustermann"],
        [14, 152, "Musterweg 2"],
        [14, 144, "8000 Alt Tylerland"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 77, "CHF"],
        [71, 77, "1 500.00"],
        [105, 39, "Annahmestelle"],
        [190, 275, "Zahlteil"],
        [190, 88, "Währung"],
        [247, 88, "Betrag"],
        [190, 76, "CHF"],
        [247, 76, "1 500.00"],
        [346, 276, "Konto / Zahlbar an"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Acme Corp"],
        [346, 244, "Hallesche Str. 37"],
        [346, 233, "3007 Hinterdupfing"],
        [346, 212, "Referenznummer"],
        [346, 201, "00 00834 96356 70000 00000 00019"],
        [346, 180, "Zahlbar durch"],
        [346, 169, "Max Mustermann"],
        [346, 158, "Musterweg 2"],
        [346, 147, "8000 Alt Tylerland"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
      end
    end

    it "renders invoice without group" do
      invoice.group = nil
      invoice.address = "Hitobito Inc.\nBelpstrasse 37\n3007 Bern"
      invoice.letter_address_position = :right
      invoice.invoice_config = InvoiceConfig.new
      invoice.invoice_items.build(name: "pens", unit_cost: 10, count: 2, vat_rate: 10)

      invoice_text = [
        [57, 796, "Hitobito Inc."],
        [57, 783, "Belpstrasse 37"],
        [57, 771, "3007 Bern"],
        [57, 685, "Rechnungsnummer:"],
        [163, 685, "1-10"],
        [57, 672, "Rechnungsdatum:"],
        [163, 672, "26.09.2022"],
        [57, 659, "Fällig bis:"],
        [163, 659, "26.10.2022"],
        [57, 646, "Rechnungssteller:"],
        [163, 646, "Top Leader"],
        [57, 632, "MwSt. Nummer:"],
        [163, 632, "CH 1234"],
        [347, 686, "Max Mustermann"],
        [347, 674, "Musterweg 2"],
        [347, 662, "8000 Alt Tylerland"],
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
        [14, 275, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Acme Corp"],
        [14, 225, "Hallesche Str. 37"],
        [14, 216, "3007 Hinterdupfing"],
        [14, 197, "Referenznummer"],
        [14, 189, "00 00834 96356 70000 00000 00019"],
        [14, 170, "Zahlbar durch"],
        [14, 161, "Max Mustermann"],
        [14, 152, "Musterweg 2"],
        [14, 144, "8000 Alt Tylerland"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 77, "CHF"],
        [71, 77, "1 500.00"],
        [105, 39, "Annahmestelle"],
        [190, 275, "Zahlteil"],
        [190, 88, "Währung"],
        [247, 88, "Betrag"],
        [190, 76, "CHF"],
        [247, 76, "1 500.00"],
        [346, 276, "Konto / Zahlbar an"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Acme Corp"],
        [346, 244, "Hallesche Str. 37"],
        [346, 233, "3007 Hinterdupfing"],
        [346, 212, "Referenznummer"],
        [346, 201, "00 00834 96356 70000 00000 00019"],
        [346, 180, "Zahlbar durch"],
        [346, 169, "Max Mustermann"],
        [346, 158, "Musterweg 2"],
        [346, 147, "8000 Alt Tylerland"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
      end
    end

    it "renders full invoice without esr_number" do
      invoice.invoice_items.build(name: "pens", unit_cost: 10, vat_rate: 10, count: 2)
      invoice.esr_number = nil
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
        [14, 275, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Acme Corp"],
        [14, 225, "Hallesche Str. 37"],
        [14, 216, "3007 Hinterdupfing"],
        [14, 197, "Zahlbar durch"],
        [14, 189, "Max Mustermann"],
        [14, 180, "Musterweg 2"],
        [14, 171, "8000 Alt Tylerland"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 77, "CHF"],
        [71, 77, "1 500.00"],
        [105, 39, "Annahmestelle"],
        [190, 275, "Zahlteil"],
        [190, 88, "Währung"],
        [247, 88, "Betrag"],
        [190, 76, "CHF"],
        [247, 76, "1 500.00"],
        [346, 276, "Konto / Zahlbar an"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Acme Corp"],
        [346, 244, "Hallesche Str. 37"],
        [346, 233, "3007 Hinterdupfing"],
        [346, 212, "Zahlbar durch"],
        [346, 201, "Max Mustermann"],
        [346, 190, "Musterweg 2"],
        [346, 179, "8000 Alt Tylerland"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
      end
    end

    it "renders full invoice in recipient language" do
      person.update!(language: :fr)
      invoice.recipient = person
      invoice.invoice_items.build(name: "pens", unit_cost: 10, vat_rate: 10, count: 2)
      invoice_text = [
        [347, 685, "No. de facture:"],
        [453, 685, "1-10"],
        [347, 672, "Date de la facture:"],
        [453, 672, "26.09.2022"],
        [347, 659, "Échue le:"],
        [453, 659, "26.10.2022"],
        [347, 646, "Auteur de la facture:"],
        [453, 646, "Top Leader"],
        [347, 632, "No TVA:"],
        [453, 632, "CH 1234"],
        [57, 686, "Max Mustermann"],
        [57, 674, "Musterweg 2"],
        [57, 662, "8000 Alt Tylerland"],
        [57, 537, "articles de factures"],
        [355, 537, "Quantité"],
        [423, 537, "Prix"],
        [455, 537, "Montant"],
        [523, 537, "TVA"],
        [57, 522, "pens"],
        [383, 522, "2"],
        [417, 522, "10.00"],
        [515, 522, "10.0%"],
        [389, 507, "Montant"],
        [502, 507, "20.00 CHF"],
        [389, 492, "TVA"],
        [506, 492, "2.00 CHF"],
        [389, 474, "montant total"],
        [490, 474, "1'500.00 CHF"],
        [14, 275, "Récépissé"],
        [14, 251, "Compte/payable à"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Acme Corp"],
        [14, 225, "Hallesche Str. 37"],
        [14, 216, "3007 Hinterdupfing"],
        [14, 197, "Numéro de référence"],
        [14, 189, "00 00834 96356 70000 00000 00019"],
        [14, 170, "Payable par"],
        [14, 161, "Max Mustermann"],
        [14, 152, "Musterweg 2"],
        [14, 144, "8000 Alt Tylerland"],
        [14, 89, "Devise"],
        [71, 89, "Montant"],
        [14, 77, "CHF"],
        [71, 77, "1 500.00"],
        [106, 39, "Point de dépôt"],
        [190, 275, "Section paiement"],
        [190, 88, "Devise"],
        [247, 88, "Montant"],
        [190, 76, "CHF"],
        [247, 76, "1 500.00"],
        [346, 276, "Compte/payable à"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Acme Corp"],
        [346, 244, "Hallesche Str. 37"],
        [346, 233, "3007 Hinterdupfing"],
        [346, 212, "Numéro de référence"],
        [346, 201, "00 00834 96356 70000 00000 00019"],
        [346, 180, "Payable par"],
        [346, 169, "Max Mustermann"],
        [346, 158, "Musterweg 2"],
        [346, 147, "8000 Alt Tylerland"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
      end
    end

    it "renders invoice in current locale when invoice does not have any recipient" do
      # Run with it instead of de, to not have standard case
      I18n.with_locale(:it) do
        invoice.invoice_items.build(name: "pens", unit_cost: 10, vat_rate: 10, count: 2)
        invoice_text = [
          [347, 685, "Numero di fattura:"],
          [464, 685, "1-10"],
          [347, 672, "Data della fattura:"],
          [464, 672, "26.09.2022"],
          [347, 659, "Scade il:"],
          [464, 659, "26.10.2022"],
          [347, 646, "Emittente della fattura:"],
          [464, 646, "Top Leader"],
          [347, 632, "Numero IVA:"],
          [464, 632, "CH 1234"],
          [57, 686, "Max Mustermann"],
          [57, 674, "Musterweg 2"],
          [57, 662, "8000 Alt Tylerland"],
          [57, 537, "L'articolo della fattura"],
          [357, 537, "Numero"],
          [413, 537, "Prezzo"],
          [457, 537, "Importo"],
          [525, 537, "IVA"],
          [57, 522, "pens"],
          [383, 522, "2"],
          [417, 522, "10.00"],
          [515, 522, "10.0%"],
          [389, 507, "Subtotale"],
          [502, 507, "20.00 CHF"],
          [389, 492, "IVA"],
          [506, 492, "2.00 CHF"],
          [389, 474, "Importo totale"],
          [490, 474, "1'500.00 CHF"],
          [14, 275, "Ricevuta"],
          [14, 251, "Conto / Pagabile a"],
          [14, 242, "CH93 0076 2011 6238 5295 7"],
          [14, 233, "Acme Corp"],
          [14, 225, "Hallesche Str. 37"],
          [14, 216, "3007 Hinterdupfing"],
          [14, 197, "Riferimento"],
          [14, 189, "00 00834 96356 70000 00000 00019"],
          [14, 170, "Pagabile da"],
          [14, 161, "Max Mustermann"],
          [14, 152, "Musterweg 2"],
          [14, 144, "8000 Alt Tylerland"],
          [14, 89, "Valuta"],
          [71, 89, "Importo"],
          [14, 77, "CHF"],
          [71, 77, "1 500.00"],
          [79, 39, "Punto di accettazione"],
          [190, 275, "Sezione pagamento"],
          [190, 88, "Valuta"],
          [247, 88, "Importo"],
          [190, 76, "CHF"],
          [247, 76, "1 500.00"],
          [346, 276, "Conto / Pagabile a"],
          [346, 265, "CH93 0076 2011 6238 5295 7"],
          [346, 254, "Acme Corp"],
          [346, 244, "Hallesche Str. 37"],
          [346, 233, "3007 Hinterdupfing"],
          [346, 212, "Riferimento"],
          [346, 201, "00 00834 96356 70000 00000 00019"],
          [346, 180, "Pagabile da"],
          [346, 169, "Max Mustermann"],
          [346, 158, "Musterweg 2"],
          [346, 147, "8000 Alt Tylerland"]
        ]

        invoice_text.each_with_index do |text, i|
          expect(text_with_position[i]).to eq(text)
        end
      end
    end

    context "multiple invoices" do
      let(:pdf) {
        described_class.render_multiple([invoice, build_invoice(recipient: people(:bottom_member))], payment_slip: true,
          articles: true, reminders: false)
      }

      before do
        person.update!(language: :fr)
        invoice.recipient = person
      end

      it "renders multiple invoices each with individual language of recipient" do
        invoice_text = [
          [347, 685, "No. de facture:"],
          [453, 685, "1-10"],
          [347, 672, "Date de la facture:"],
          [453, 672, "26.09.2022"],
          [347, 659, "Échue le:"],
          [453, 659, "26.10.2022"],
          [347, 646, "Auteur de la facture:"],
          [453, 646, "Top Leader"],
          [347, 632, "No TVA:"],
          [453, 632, "CH 1234"],
          [57, 686, "Max Mustermann"],
          [57, 674, "Musterweg 2"],
          [57, 662, "8000 Alt Tylerland"],
          [57, 537, "articles de factures"],
          [405, 537, "Quantité"],
          [473, 537, "Prix"],
          [505, 537, "Montant"],
          [389, 522, "Montant"],
          [506, 522, "0.00 CHF"],
          [389, 504, "montant total"],
          [490, 504, "1'500.00 CHF"],
          [14, 275, "Récépissé"],
          [14, 251, "Compte/payable à"],
          [14, 242, "CH93 0076 2011 6238 5295 7"],
          [14, 233, "Acme Corp"],
          [14, 225, "Hallesche Str. 37"],
          [14, 216, "3007 Hinterdupfing"],
          [14, 197, "Numéro de référence"],
          [14, 189, "00 00834 96356 70000 00000 00019"],
          [14, 170, "Payable par"],
          [14, 161, "Max Mustermann"],
          [14, 152, "Musterweg 2"],
          [14, 144, "8000 Alt Tylerland"],
          [14, 89, "Devise"],
          [71, 89, "Montant"],
          [14, 77, "CHF"],
          [71, 77, "1 500.00"],
          [106, 39, "Point de dépôt"],
          [190, 275, "Section paiement"],
          [190, 88, "Devise"],
          [247, 88, "Montant"],
          [190, 76, "CHF"],
          [247, 76, "1 500.00"],
          [346, 276, "Compte/payable à"],
          [346, 265, "CH93 0076 2011 6238 5295 7"],
          [346, 254, "Acme Corp"],
          [346, 244, "Hallesche Str. 37"],
          [346, 233, "3007 Hinterdupfing"],
          [346, 212, "Numéro de référence"],
          [346, 201, "00 00834 96356 70000 00000 00019"],
          [346, 180, "Payable par"],
          [346, 169, "Max Mustermann"],
          [346, 158, "Musterweg 2"],
          [346, 147, "8000 Alt Tylerland"],
          [57, 537, "Rechnungsartikel"],
          [412, 537, "Anzahl"],
          [469, 537, "Preis"],
          [512, 537, "Betrag"],
          [405, 522, "Zwischenbetrag"],
          [506, 522, "0.00 CHF"],
          [405, 504, "Gesamtbetrag"],
          [506, 504, "0.00 CHF"]
        ]

        invoice_text.each_with_index do |text, i|
          expect(text_with_position[i]).to eq(text)
        end
      end
    end
  end

  context "group invoices" do
    let(:invoice) do
      Invoice.create!(
        payment_slip: :qr,
        total: 1500,
        iban: "CH93 0076 2011 6238 5295 7",
        reference: "RF561A",
        esr_number: "00 00834 96356 70000 00000 00019",
        issued_at: Date.new(2022, 9, 26),
        due_at: Date.new(2022, 10, 26),
        creator: person,
        vat_number: "CH 1234",
        sequence_number: "1-10",
        group: group,
        recipient: group,
        title: "Group Invoice"
      )
    end

    before do
      group.update!(street: "Groupstreet", housenumber: 13, zip_code: 6767, town: "Grouptown", country: "CH")
    end

    it "renders invoice with group address" do
      invoice_text = [
        [57, 796, "top layer address"],
        [347, 685, "Rechnungsnummer:"],
        [453, 685, "834963567-1"],
        [347, 672, "Rechnungsdatum:"],
        [453, 672, "26.09.2022"],
        [347, 659, "Fällig bis:"],
        [453, 659, "26.10.2022"],
        [347, 646, "Rechnungssteller:"],
        [453, 646, "Top Leader"],
        [347, 632, "MwSt. Nummer:"],
        [453, 632, "CH 1234"],
        [57, 686, "Top"],
        [57, 674, "Groupstreet 13"],
        [57, 662, "6767 Grouptown"],
        [57, 554, "Group Invoice"],
        [57, 521, "Rechnungsartikel"],
        [412, 521, "Anzahl"],
        [469, 521, "Preis"],
        [512, 521, "Betrag"],
        [405, 506, "Zwischenbetrag"],
        [506, 506, "0.00 CHF"],
        [405, 488, "Gesamtbetrag"],
        [506, 488, "0.00 CHF"],
        [14, 275, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Hitobito AG"],
        [14, 225, "Belpstrasse 37"],
        [14, 216, "3007 Bern"],
        [14, 197, "Referenznummer"],
        [14, 189, "00 00834 96356 70000 00000 00019"],
        [14, 170, "Zahlbar durch"],
        [14, 161, "Top"],
        [14, 152, "Groupstreet 13"],
        [14, 144, "6767 Grouptown"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 77, "CHF"],
        [105, 39, "Annahmestelle"],
        [190, 275, "Zahlteil"],
        [190, 88, "Währung"],
        [247, 88, "Betrag"],
        [190, 76, "CHF"],
        [346, 276, "Konto / Zahlbar an"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Hitobito AG"],
        [346, 244, "Belpstrasse 37"],
        [346, 233, "3007 Bern"],
        [346, 212, "Referenznummer"],
        [346, 201, "00 00834 96356 70000 00000 00019"],
        [346, 180, "Zahlbar durch"],
        [346, 169, "Top"],
        [346, 158, "Groupstreet 13"],
        [346, 147, "6767 Grouptown"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
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
      expect(subject).to match "Gesamtbetrag 5.35 EUR"
      expect(subject).not_to match "CHF"
    end
  end

  describe "payment_reminder" do
    let(:due_at) { sent.due_at + 10.days }
    let(:reminders) { true }
    let(:show) { true }
    let(:pdf) { described_class.render(sent, articles: true, reminders: reminders) }
    let!(:reminder) { Fabricate(:payment_reminder, invoice: sent, due_at: due_at, show_invoice_description: show) }

    subject { PDF::Inspector::Text.analyze(pdf).show_text }

    before do
      sent.update(description: "Existing text")
    end

    context "with default show_invoice_description: true" do
      it "includes payment reminder title and text" do
        is_expected.to include("#{reminder.title} - #{sent.title}")
        is_expected.to include(sent.description)
        is_expected.to include(reminder.text)
      end
    end

    context "with show_invoice_description: false" do
      let(:show) { false }

      it "only shows payment reminder title and text" do
        is_expected.to include("#{reminder.title} - #{sent.title}")
        is_expected.not_to include(sent.description)
        is_expected.to(include reminder.text)
      end
    end

    context "with option reminders: false" do
      let(:reminders) { false }

      it "does not include payment reminders" do
        is_expected.not_to include("#{reminder.title} - #{sent.title}")
        is_expected.not_to include(reminder.text)
      end
    end
  end

  describe "normal invoice" do
    before { invoice.update(description: "We want your moneyz") }

    subject { PDF::Inspector::Text.analyze(pdf).show_text }

    it "includes title" do
      is_expected.to include(invoice.title)
    end

    it "includes text" do
      is_expected.to include(invoice.description)
    end
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
      expect(subject.show_text.first).to eq "042>000083496356700000000000027+ 1>"
    end

    it "with ch_besr" do
      invoice.payment_slip = "ch_besr"
      expect(subject.positions).to eq [[323.58191, 44.53291]]
      expect(subject.show_text.first).to eq "042>000083496356700000000000027+ 1>"
    end

    it "with ch_besr" do
      invoice.payment_slip = "ch_besr"
      expect(subject.positions).to eq [[323.58191, 44.53291]]
      expect(subject.show_text.first).to eq "042>000083496356700000000000027+ 1>"
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
        payee_name: "Acme Corp",
        payee_street: "Hallesche Str.",
        payee_housenumber: "37",
        payee_zip_code: "3007",
        payee_town: "Hinterdupfing",
        recipient_name: "Max Mustermann",
        recipient_street: "Musterweg",
        recipient_housenumber: "2",
        recipient_zip_code: "8000",
        recipient_town: "Alt Tylerland"
      )
    end

    let(:pdf) { described_class.render(invoice, payment_slip: true) }

    subject { PDF::Inspector::Text.analyze(pdf) }

    it "renders qrcode" do
      invoice_text = [
        [14, 275, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Acme Corp"],
        [14, 225, "Hallesche Str. 37"],
        [14, 216, "3007 Hinterdupfing"],
        [14, 197, "Referenznummer"],
        [14, 189, "00 00834 96356 70000 00000 00019"],
        [14, 170, "Zahlbar durch"],
        [14, 161, "Max Mustermann"],
        [14, 152, "Musterweg 2"],
        [14, 144, "8000 Alt Tylerland"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 77, "CHF"],
        [71, 77, "1 500.00"],
        [105, 39, "Annahmestelle"],
        [190, 275, "Zahlteil"],
        [190, 88, "Währung"],
        [247, 88, "Betrag"],
        [190, 76, "CHF"],
        [247, 76, "1 500.00"],
        [346, 276, "Konto / Zahlbar an"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Acme Corp"],
        [346, 244, "Hallesche Str. 37"],
        [346, 233, "3007 Hinterdupfing"],
        [346, 212, "Referenznummer"],
        [346, 201, "00 00834 96356 70000 00000 00019"],
        [346, 180, "Zahlbar durch"],
        [346, 169, "Max Mustermann"],
        [346, 158, "Musterweg 2"],
        [346, 147, "8000 Alt Tylerland"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
      end
    end

    it "does not render blank amount" do
      invoice.total = 0
      invoice_text = [
        [14, 275, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Acme Corp"],
        [14, 225, "Hallesche Str. 37"],
        [14, 216, "3007 Hinterdupfing"],
        [14, 197, "Referenznummer"],
        [14, 189, "00 00834 96356 70000 00000 00019"],
        [14, 170, "Zahlbar durch"],
        [14, 161, "Max Mustermann"],
        [14, 152, "Musterweg 2"],
        [14, 144, "8000 Alt Tylerland"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 77, "CHF"],
        [105, 39, "Annahmestelle"],
        [190, 275, "Zahlteil"],
        [190, 88, "Währung"],
        [247, 88, "Betrag"],
        [190, 76, "CHF"],
        [346, 276, "Konto / Zahlbar an"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Acme Corp"],
        [346, 244, "Hallesche Str. 37"],
        [346, 233, "3007 Hinterdupfing"],
        [346, 212, "Referenznummer"],
        [346, 201, "00 00834 96356 70000 00000 00019"],
        [346, 180, "Zahlbar durch"],
        [346, 169, "Max Mustermann"],
        [346, 158, "Musterweg 2"],
        [346, 147, "8000 Alt Tylerland"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
      end
    end

    it "does not render receipt and payment amount if total is hidden" do
      invoice.hide_total = true
      invoice_text = [
        [14, 275, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Acme Corp"],
        [14, 225, "Hallesche Str. 37"],
        [14, 216, "3007 Hinterdupfing"],
        [14, 197, "Referenznummer"],
        [14, 189, "00 00834 96356 70000 00000 00019"],
        [14, 170, "Zahlbar durch"],
        [14, 161, "Max Mustermann"],
        [14, 152, "Musterweg 2"],
        [14, 144, "8000 Alt Tylerland"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 77, "CHF"],
        [105, 39, "Annahmestelle"],
        [190, 275, "Zahlteil"],
        [190, 88, "Währung"],
        [247, 88, "Betrag"],
        [190, 76, "CHF"],
        [346, 276, "Konto / Zahlbar an"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Acme Corp"],
        [346, 244, "Hallesche Str. 37"],
        [346, 233, "3007 Hinterdupfing"],
        [346, 212, "Referenznummer"],
        [346, 201, "00 00834 96356 70000 00000 00019"],
        [346, 180, "Zahlbar durch"],
        [346, 169, "Max Mustermann"],
        [346, 158, "Musterweg 2"],
        [346, 147, "8000 Alt Tylerland"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
      end
    end

    describe "with deprecated address values" do
      let(:invoice) do
        build_invoice(
          sequence_number: "1-1",
          payment_slip: :qr,
          total: 1500,
          iban: "CH93 0076 2011 6238 5295 7",
          reference: "RF561A",
          esr_number: "00 00834 96356 70000 00000 00019",
          deprecated_payee: "Deprecated Acme Corp\nHallesche Str. 37\n3007 Hinterdupfing",
          deprecated_recipient_address: "Deprecated Max Mustermann\nMusterweg 2\n8000 Alt Tylerland"
        )
      end

      it "uses deprecated values" do
        invoice.hide_total = true
        invoice_text = [
          [14, 275, "Empfangsschein"],
          [14, 251, "Konto / Zahlbar an"],
          [14, 242, "CH93 0076 2011 6238 5295 7"],
          [14, 233, "Deprecated Acme Corp"],
          [14, 225, "Hallesche Str. 37"],
          [14, 216, "3007 Hinterdupfing"],
          [14, 197, "Referenznummer"],
          [14, 189, "00 00834 96356 70000 00000 00019"],
          [14, 170, "Zahlbar durch"],
          [14, 161, "Deprecated Max Mustermann"],
          [14, 152, "Musterweg 2"],
          [14, 144, "8000 Alt Tylerland"]
        ]

        invoice_text.each_with_index do |text, i|
          expect(text_with_position[i]).to eq(text)
        end
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
        invoice.update!(address: "Absender Adresse 5")
        invoice.invoice_config.logo.attach fixture_file_upload("images/logo.png")
        expect(invoice.invoice_config.logo).to be_attached
      end

      it "with logo_position=disabled it does not render logo" do
        invoice.invoice_config.update(logo_position: :disabled)
        expect(image_positions).to be_empty
      end

      it "with logo_position=left it renders logo on the left and address on the right" do
        invoice.invoice_config.update(logo_position: :left)
        expect(image_positions).to have(1).item
        expect(image_positions.first).to match(
          displayed_height: 900.0,
          displayed_width: 52_900.0,
          height: 30,
          width: 230,
          x: 56.69291,
          y: 775.19709
        )
        expect(text_with_position).to include [347, 796, "Absender Adresse 5"]
      end

      it "with logo_position=right it renders logo on the right and address on the left" do
        invoice.invoice_config.update(logo_position: :right)
        expect(image_positions).to have(1).item
        expect(image_positions.first).to match(
          displayed_height: 900.0,
          displayed_width: 52_900.0,
          height: 30,
          width: 230,
          x: 308.58709,
          y: 775.19709
        )
        expect(text_with_position).to include [57, 796, "Absender Adresse 5"]
      end
    end
  end
end
