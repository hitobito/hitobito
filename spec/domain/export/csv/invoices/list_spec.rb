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
  let(:csv) { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) }

  subject { csv }

  its(:headers) do
    is_expected.to == [
      "Titel", "Nummer", "Status", "Referenz Nummer", "Text", "Empfänger E-Mail",
      "Empfänger Adresse", "Verschickt am", "Fällig am", "Betrag",
      "MwSt.", "Total inkl. MwSt.", "Total bezahlt",
      "Kostenstellen", "Konten", "Zahlungseingänge",
    ]
  end

  it "has 2 items" do
    expect(subject.size).to eq(2)
  end

  context "first row" do
    subject { csv[0] }

    its(["Titel"]) { is_expected.to == "Invoice" }
    its(["Nummer"]) { is_expected.to == invoices(:invoice).sequence_number }
    its(["Status"]) { is_expected.to == "Entwurf" }
    its(["Referenz Nummer"]) { is_expected.to == invoices(:invoice).esr_number }
    its(["Betrag"]) { is_expected.to == "5.00" }
    its(["MwSt."]) { is_expected.to == "0.35" }
    its(["Total inkl. MwSt."]) { is_expected.to == "5.35" }
    its(["Total bezahlt"]) { is_expected.to == "0.00" }
    its(["Empfänger E-Mail"]) { is_expected.to == "top_leader@example.com" }
    its(["Beschreibung"]) { is_expected.to.nil? }
    its(["Empfänger Adresse"]) { is_expected.to.nil? }
    its(["Verschickt am"]) { is_expected.to.nil? }
    its(["Fällig am"]) { is_expected.to.nil? }
  end

  context "second row" do
    subject { csv[1] }

    let(:invoice) { invoices(:sent) }

    its(["Titel"]) { is_expected.to == "Sent" }
    its(["Nummer"]) { is_expected.to == invoice.sequence_number }
    its(["Status"]) { is_expected.to == "per Mail versendet" }
    its(["Referenz Nummer"]) { is_expected.to == invoice.esr_number }
    its(["Verschickt am"]) { is_expected.to == I18n.l(invoice.sent_at) }
    its(["Fällig am"]) { is_expected.to == I18n.l(invoice.due_at) }
    its(["Betrag"]) { is_expected.to == "0.50" }
    its(["MwSt."]) { is_expected.to == "0.00" }
    its(["Total inkl. MwSt."]) { is_expected.to == "0.50" }
    its(["Total bezahlt"]) { is_expected.to == "0.00" }
    its(["Empfänger E-Mail"]) { is_expected.to == "top_leader@example.com" }
    its(["Beschreibung"]) { is_expected.to.nil? }
    its(["Empfänger Adresse"]) { is_expected.to.nil? }
  end
end
