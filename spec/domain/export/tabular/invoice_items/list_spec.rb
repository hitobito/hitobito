# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::InvoiceItems::List do
  let(:invoice) { invoices(:invoice) }
  let(:item) { invoice_items(:pens) }

  subject(:list) { described_class.new([item]) }

  it "exports the item attributes followed by those of its invoice" do
    expect(list.attributes).to eq [
      :name, :account, :cost_center, :count, :unit_cost, :cost, :vat_rate, :vat, :total,
      :title, :sequence_number, :state, :esr_number, :description,
      :recipient_email, :recipient_address, :sent_at, :due_at,
      :recipient_company_name, :recipient_name, :recipient_first_name, :recipient_last_name,
      :recipient_address_care_of, :recipient_street, :recipient_housenumber,
      :recipient_postbox, :recipient_zip_code, :recipient_town, :recipient_country,
      :payee_name, :payee_street, :payee_housenumber, :payee_zip_code, :payee_town,
      :payee_country
    ]
  end

  it "labels the item attributes with the invoice item translations" do
    expect(list.labels.first(9)).to eq [
      "Name", "Konto", "Kostenstelle", "Anzahl", "Preis", "Betrag", "MwSt.",
      "MwSt. Betrag", "Total"
    ]
  end

  it "labels the remaining attributes with the invoice translations" do
    expect(list.labels[9, 9]).to eq [
      "Titel", "Nummer", "Status", "Referenz Nummer", "Text", "Empfänger E-Mail",
      "Empfänger Adresse", "Verschickt am", "Fällig am"
    ]
    expect(list.labels.last(6)).to eq [
      "Zahlungsempfänger Name", "Zahlungsempfänger Strasse", "Zahlungsempfänger Hausnummer",
      "Zahlungsempfänger PLZ", "Zahlungsempfänger Ort", "Zahlungsempfänger Land"
    ]
  end

  it "does not export the aggregated amounts and payments of the invoice" do
    expect(list.attributes).not_to include(:amount_paid, :cost_centers, :accounts, :payments)
  end

  describe "csv" do
    let(:csv) do
      CSV.parse(described_class.csv(invoice.invoice_items),
        headers: true, col_sep: Settings.csv.separator)
    end

    it "writes one row per invoice item" do
      expect(csv.size).to eq invoice.invoice_items.count
      expect(csv.size).to eq 2
    end

    it "repeats the invoice data on every row" do
      expect(csv.pluck("Titel").uniq).to eq [invoice.title]
      expect(csv.pluck("Nummer").uniq).to eq [invoice.sequence_number]
      expect(csv.pluck("Empfänger E-Mail").uniq).to eq [invoice.recipient_email]
    end

    it "writes the amounts of the individual item" do
      row = csv.find { |r| r["Anzahl"] == "3" }
      expect(row.to_h.slice("Preis", "Betrag", "MwSt.", "MwSt. Betrag", "Total"))
        .to eq({"Preis" => "1.50", "Betrag" => "4.50", "MwSt." => "8.0",
                "MwSt. Betrag" => "0.36", "Total" => "4.86"})
    end
  end
end
