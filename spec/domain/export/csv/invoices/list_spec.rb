#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "csv"

describe Export::Tabular::Invoices::List do
  let(:group) { groups(:bottom_layer_one) }

  let(:list) { group.invoices }
  let(:data) { Export::Tabular::Invoices::List.csv(list) }
  let(:data_without_bom) { data.gsub(Regexp.new("^#{Export::Csv::UTF8_BOM}"), "") }
  let(:csv) { CSV.parse(data_without_bom, headers: true, col_sep: Settings.csv.separator) }

  subject { csv }

  its(:headers) do
    should == [
      "Titel", "Nummer", "Status", "Referenz Nummer", "Text", "Empfänger E-Mail",
      "Empfänger Adresse", "Verschickt am", "Fällig am", "Betrag",
      "MwSt.", "Rechnungsbetrag", "Bezahlt",
      "Kostenstellen", "Konten", "Zahlungseingänge",
      "Empfänger Firmenname", "Empfänger Name", "Empfänger zusätz. Adresszeile",
      "Empfänger Strasse", "Empfänger Hausnummer", "Empfänger Postfach", "Empfänger PLZ",
      "Empfänger Ort", "Empfänger Land", "Zahlungsempfänger Name", "Zahlungsempfänger Strasse",
      "Zahlungsempfänger Hausnummer", "Zahlungsempfänger PLZ", "Zahlungsempfänger Ort",
      "Zahlungsempfänger Land"
    ]
  end

  it "has 2 items" do
    expect(subject.size).to eq(2)
  end

  context "first row" do
    subject { csv[0] }

    its(["Titel"]) { should == "Invoice" }
    its(["Nummer"]) { should == invoices(:invoice).sequence_number }
    its(["Status"]) { should == "Entwurf" }
    its(["Referenz Nummer"]) { should == invoices(:invoice).esr_number }
    its(["Betrag"]) { should == "5.00" }
    its(["MwSt."]) { should == "0.35" }
    its(["Rechnungsbetrag"]) { should == "5.35" }
    its(["Bezahlt"]) { should == "0.00" }
    its(["Empfänger E-Mail"]) { should == "top_leader@example.com" }
    its(["Beschreibung"]) { should.nil? }
    its(["Empfänger Adresse"]) { should.nil? }
    its(["Verschickt am"]) { should.nil? }
    its(["Fällig am"]) { should.nil? }
    its(["Empfänger Firmenname"]) { should == invoices(:invoice).recipient_company_name }
    its(["Empfänger Name"]) { should == invoices(:invoice).recipient_name }
    its(["Empfänger zusätz. Adresszeile"]) { should == invoices(:invoice).recipient_address_care_of }
    its(["Empfänger Strasse"]) { should == invoices(:invoice).recipient_street }
    its(["Empfänger Hausnummer"]) { should == invoices(:invoice).recipient_housenumber }
    its(["Empfänger Postfach"]) { should == invoices(:invoice).recipient_postbox }
    its(["Empfänger PLZ"]) { should == invoices(:invoice).recipient_zip_code }
    its(["Empfänger Ort"]) { should == invoices(:invoice).recipient_town }
    its(["Empfänger Land"]) { should == invoices(:invoice).recipient_country }
    its(["Zahlungsempfänger Name"]) { should == invoices(:invoice).payee_name }
    its(["Zahlungsempfänger Strasse"]) { should == invoices(:invoice).payee_street }
    its(["Zahlungsempfänger Hausnummer"]) { should == invoices(:invoice).payee_housenumber }
    its(["Zahlungsempfänger PLZ"]) { should == invoices(:invoice).payee_zip_code }
    its(["Zahlungsempfänger Ort"]) { should == invoices(:invoice).payee_town }
    its(["Zahlungsempfänger Land"]) { should == invoices(:invoice).payee_country }
  end

  context "second row" do
    subject { csv[1] }

    let(:invoice) { invoices(:sent) }

    its(["Titel"]) { should == "Sent" }
    its(["Nummer"]) { should == invoice.sequence_number }
    its(["Status"]) { should == "per Mail versendet" }
    its(["Referenz Nummer"]) { should == invoice.esr_number }
    its(["Verschickt am"]) { should == I18n.l(invoice.sent_at) }
    its(["Fällig am"]) { should == I18n.l(invoice.due_at) }
    its(["Betrag"]) { should == "0.50" }
    its(["MwSt."]) { should == "0.00" }
    its(["Rechnungsbetrag"]) { should == "0.50" }
    its(["Bezahlt"]) { should == "0.00" }
    its(["Empfänger E-Mail"]) { should == "top_leader@example.com" }
    its(["Beschreibung"]) { should.nil? }
    its(["Empfänger Adresse"]) { should.nil? }
    its(["Empfänger Firmenname"]) { should == invoice.recipient_company_name }
    its(["Empfänger Name"]) { should == invoice.recipient_name }
    its(["Empfänger zusätz. Adresszeile"]) { should == invoice.recipient_address_care_of }
    its(["Empfänger Strasse"]) { should == invoice.recipient_street }
    its(["Empfänger Hausnummer"]) { should == invoice.recipient_housenumber }
    its(["Empfänger Postfach"]) { should == invoice.recipient_postbox }
    its(["Empfänger PLZ"]) { should == invoice.recipient_zip_code }
    its(["Empfänger Ort"]) { should == invoice.recipient_town }
    its(["Empfänger Land"]) { should == invoice.recipient_country }
    its(["Zahlungsempfänger Name"]) { should == invoice.payee_name }
    its(["Zahlungsempfänger Strasse"]) { should == invoice.payee_street }
    its(["Zahlungsempfänger Hausnummer"]) { should == invoice.payee_housenumber }
    its(["Zahlungsempfänger PLZ"]) { should == invoice.payee_zip_code }
    its(["Zahlungsempfänger Ort"]) { should == invoice.payee_town }
    its(["Zahlungsempfänger Land"]) { should == invoice.payee_country }
  end
end
