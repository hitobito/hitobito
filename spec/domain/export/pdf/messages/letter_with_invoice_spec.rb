# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Messages::LetterWithInvoice do
  include PdfHelpers

  let(:letter) { messages(:with_invoice) }
  let(:options) { {} }
  let(:group) { groups(:top_layer) }
  let(:bottom_member) { people(:bottom_member) }

  let(:pdf) { described_class.new(letter, options) }

  subject { pdf }

  before { invoice_configs(:top_layer).update(payment_slip: :qr, payee: "Hans Gerber\nEine Strasse 42\n1234 Dorf") }

  before do
    Subscription.create!(mailing_list: letter.mailing_list,
      subscriber: group,
      role_types: [Group::BottomGroup::Member])
    Fabricate(Group::BottomGroup::Member.name, group: groups(:bottom_group_one_one), person: bottom_member)
    Messages::LetterDispatch.new(letter).run
  end

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
      invoice_text = [
        [71, 654, "Bottom Member"],
        [71, 644, "Greatstreet 345"],
        [71, 633, "3456 Greattown"],
        [71, 531, "Mitgliedsbeitrag"],
        [71, 502, "Hallo"],
        [71, 481, "Dein "],
        [92, 481, "Mitgliedsbeitrag"],
        [161, 481, " ist fällig! "],
        [71, 460, "Bis bald"],
        [28, 290, "Empfangsschein"],
        [28, 265, "Konto / Zahlbar an"],
        [28, 255, "CH93 0076 2011 6238 5295 7"],
        [28, 246, "Hans Gerber"],
        [28, 237, "Eine Strasse 42"],
        [28, 228, "1234 Dorf"],
        [28, 208, "Referenznummer"],
        [28, 199, "00 00834 96356 70000 00000 00019"],
        [28, 180, "Zahlbar durch"],
        [28, 170, "Bottom Member"],
        [28, 161, "Greatstreet 345"],
        [28, 152, "3456 Greattown"],
        [28, 103, "Währung"],
        [85, 103, "Betrag"],
        [28, 91, "CHF"],
        [85, 91, "10.00"],
        [119, 53, "Annahmestelle"],
        [204, 290, "Zahlteil"],
        [204, 102, "Währung"],
        [261, 102, "Betrag"],
        [204, 90, "CHF"],
        [261, 90, "10.00"],
        [360, 290, "Konto / Zahlbar an"],
        [360, 279, "CH93 0076 2011 6238 5295 7"],
        [360, 267, "Hans Gerber"],
        [360, 255, "Eine Strasse 42"],
        [360, 244, "1234 Dorf"],
        [360, 222, "Referenznummer"],
        [360, 210, "00 00834 96356 70000 00000 00019"],
        [360, 189, "Zahlbar durch"],
        [360, 177, "Bottom Member"],
        [360, 165, "Greatstreet 345"],
        [360, 154, "3456 Greattown"]
      ]

      invoice_text.each_with_index do |text, i|
        expect(text_with_position[i]).to eq(text)
      end
    end

    context "persisted invoice list" do
      it "renders iban from invoice config when no persisted invoice exists" do
        group.invoice_config.update(iban: "CH10 0221 1981 6169 5329 8")
        expect(text_with_position).to include([360, 279, "CH10 0221 1981 6169 5329 8"])
      end

      it "renders iban from invoice when persisted invoice exists" do
        list = InvoiceList.create(group: group, title: "title")
        list.invoices.create!(title: :title, recipient_id: bottom_member.id, total: 10, group: group)
        letter.invoice_list_id = list.id

        group.invoice_config.update!(iban: "CH10 0221 1981 6169 5329 8")
        expect(text_with_position).to include([360, 279, "CH93 0076 2011 6238 5295 7"])
      end

      it "mixes person and invoice address" do
        list = InvoiceList.create!(group: group, title: "title")
        list.invoices.create!(title: :title, recipient_id: bottom_member.id, total: 10, group: group)
        letter.invoice_list_id = list.id

        letter.message_recipients.first.update!(address: "Foo Member\nGreatstreet 345\n3456 Greattown")

        described_class.new(letter).render
        expect(text_with_position).to include([71, 654, "Foo Member"])
        expect(text_with_position).to include([360, 177, "Bottom Member"])
      end
    end

    context "dynamic" do
      before do
        people(:top_leader).update!(street: "Funkystreet", housenumber: "42", zip_code: "4242")
        Fabricate(Group::BottomGroup::Member.name, group: groups(:bottom_group_one_one), person: people(:top_leader))
        Messages::LetterDispatch.new(letter).run
      end

      context "stamped" do
        let(:options) { {stamped: true} }

        it "renders only some texts positions" do
          invoice_text = [
            [71, 654, "Top Leader"],
            [71, 644, "Funkystreet 42"],
            [71, 633, "4242 Greattown"],
            [28, 290, "Empfangsschein"],
            [28, 265, "Konto / Zahlbar an"],
            [28, 255, "CH93 0076 2011 6238 5295 7"],
            [28, 246, "Hans Gerber"],
            [28, 237, "Eine Strasse 42"],
            [28, 228, "1234 Dorf"],
            [28, 208, "Referenznummer"],
            [28, 199, "00 00834 96356 70000 00000 00019"],
            [28, 180, "Zahlbar durch"],
            [28, 170, "Top Leader"],
            [28, 161, "Funkystreet 42"],
            [28, 152, "4242 Greattown"],
            [28, 103, "Währung"],
            [85, 103, "Betrag"],
            [28, 91, "CHF"],
            [85, 91, "10.00"],
            [119, 53, "Annahmestelle"],
            [360, 290, "Konto / Zahlbar an"],
            [360, 279, "CH93 0076 2011 6238 5295 7"],
            [360, 267, "Hans Gerber"],
            [360, 255, "Eine Strasse 42"],
            [360, 244, "1234 Dorf"],
            [360, 222, "Referenznummer"],
            [360, 210, "00 00834 96356 70000 00000 00019"],
            [360, 189, "Zahlbar durch"],
            [360, 177, "Top Leader"],
            [360, 165, "Funkystreet 42"],
            [360, 154, "4242 Greattown"],
            [71, 654, "Bottom Member"],
            [71, 644, "Greatstreet 345"],
            [71, 633, "3456 Greattown"],
            [28, 290, "Empfangsschein"],
            [28, 265, "Konto / Zahlbar an"],
            [28, 255, "CH93 0076 2011 6238 5295 7"],
            [28, 246, "Hans Gerber"],
            [28, 237, "Eine Strasse 42"],
            [28, 228, "1234 Dorf"],
            [28, 208, "Referenznummer"],
            [28, 199, "00 00834 96356 70000 00000 00019"],
            [28, 180, "Zahlbar durch"],
            [28, 170, "Bottom Member"],
            [28, 161, "Greatstreet 345"],
            [28, 152, "3456 Greattown"],
            [28, 103, "Währung"],
            [85, 103, "Betrag"],
            [28, 91, "CHF"],
            [85, 91, "10.00"],
            [119, 53, "Annahmestelle"],
            [360, 290, "Konto / Zahlbar an"],
            [360, 279, "CH93 0076 2011 6238 5295 7"],
            [360, 267, "Hans Gerber"],
            [360, 255, "Eine Strasse 42"],
            [360, 244, "1234 Dorf"],
            [360, 222, "Referenznummer"],
            [360, 210, "00 00834 96356 70000 00000 00019"],
            [360, 189, "Zahlbar durch"],
            [360, 177, "Bottom Member"],
            [360, 165, "Greatstreet 345"],
            [360, 154, "3456 Greattown"]
          ]

          invoice_text.each_with_index do |text, i|
            expect(text_with_position[i]).to eq(text)
          end
        end
      end

      it "renders all texts at positions" do
        invoice_text = [
          [71, 654, "Top Leader"],
          [71, 644, "Funkystreet 42"],
          [71, 633, "4242 Greattown"],
          [71, 531, "Mitgliedsbeitrag"],
          [71, 502, "Hallo"],
          [71, 481, "Dein "],
          [92, 481, "Mitgliedsbeitrag"],
          [161, 481, " ist fällig! "],
          [71, 460, "Bis bald"],
          [28, 290, "Empfangsschein"],
          [28, 265, "Konto / Zahlbar an"],
          [28, 255, "CH93 0076 2011 6238 5295 7"],
          [28, 246, "Hans Gerber"],
          [28, 237, "Eine Strasse 42"],
          [28, 228, "1234 Dorf"],
          [28, 208, "Referenznummer"],
          [28, 199, "00 00834 96356 70000 00000 00019"],
          [28, 180, "Zahlbar durch"],
          [28, 170, "Top Leader"],
          [28, 161, "Funkystreet 42"],
          [28, 152, "4242 Greattown"],
          [28, 103, "Währung"],
          [85, 103, "Betrag"],
          [28, 91, "CHF"],
          [85, 91, "10.00"],
          [119, 53, "Annahmestelle"],
          [204, 290, "Zahlteil"],
          [204, 102, "Währung"],
          [261, 102, "Betrag"],
          [204, 90, "CHF"],
          [261, 90, "10.00"],
          [360, 290, "Konto / Zahlbar an"],
          [360, 279, "CH93 0076 2011 6238 5295 7"],
          [360, 267, "Hans Gerber"],
          [360, 255, "Eine Strasse 42"],
          [360, 244, "1234 Dorf"],
          [360, 222, "Referenznummer"],
          [360, 210, "00 00834 96356 70000 00000 00019"],
          [360, 189, "Zahlbar durch"],
          [360, 177, "Top Leader"],
          [360, 165, "Funkystreet 42"],
          [360, 154, "4242 Greattown"],
          [71, 654, "Bottom Member"],
          [71, 644, "Greatstreet 345"],
          [71, 633, "3456 Greattown"],
          [71, 531, "Mitgliedsbeitrag"],
          [71, 502, "Hallo"],
          [71, 481, "Dein "],
          [92, 481, "Mitgliedsbeitrag"],
          [161, 481, " ist fällig! "],
          [71, 460, "Bis bald"],
          [28, 290, "Empfangsschein"],
          [28, 265, "Konto / Zahlbar an"],
          [28, 255, "CH93 0076 2011 6238 5295 7"],
          [28, 246, "Hans Gerber"],
          [28, 237, "Eine Strasse 42"],
          [28, 228, "1234 Dorf"],
          [28, 208, "Referenznummer"],
          [28, 199, "00 00834 96356 70000 00000 00019"],
          [28, 180, "Zahlbar durch"],
          [28, 170, "Bottom Member"],
          [28, 161, "Greatstreet 345"],
          [28, 152, "3456 Greattown"],
          [28, 103, "Währung"],
          [85, 103, "Betrag"],
          [28, 91, "CHF"],
          [85, 91, "10.00"],
          [119, 53, "Annahmestelle"],
          [204, 290, "Zahlteil"],
          [204, 102, "Währung"],
          [261, 102, "Betrag"],
          [204, 90, "CHF"],
          [261, 90, "10.00"],
          [360, 290, "Konto / Zahlbar an"],
          [360, 279, "CH93 0076 2011 6238 5295 7"],
          [360, 267, "Hans Gerber"],
          [360, 255, "Eine Strasse 42"],
          [360, 244, "1234 Dorf"],
          [360, 222, "Referenznummer"],
          [360, 210, "00 00834 96356 70000 00000 00019"],
          [360, 189, "Zahlbar durch"],
          [360, 177, "Bottom Member"],
          [360, 165, "Greatstreet 345"],
          [360, 154, "3456 Greattown"]
        ]

        invoice_text.each_with_index do |text, i|
          expect(text_with_position[i]).to eq(text)
        end
      end
    end
  end
end
