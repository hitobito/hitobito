#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::Invoices::List do
  let(:invoice) { invoices(:invoice) }
  let(:list) { Export::Tabular::Invoices::List.new([invoice]) }

  subject { list }

  it "uses certain attributes with tranlsations" do
    expect(subject.attributes).to eq [:title,
      :sequence_number,
      :state,
      :esr_number,
      :description,
      :recipient_email,
      :recipient_address,
      :sent_at,
      :due_at,
      :cost,
      :vat,
      :total,
      :amount_paid,
      :cost_centers,
      :accounts,
      :payments,
      :recipient_company_name,
      :recipient_name,
      :recipient_address_care_of,
      :recipient_street,
      :recipient_housenumber,
      :recipient_postbox,
      :recipient_zip_code,
      :recipient_town,
      :recipient_country,
      :payee_name,
      :payee_street,
      :payee_housenumber,
      :payee_zip_code,
      :payee_town,
      :payee_country]

    expect(subject.labels).to eq ["Titel",
      "Nummer",
      "Status",
      "Referenz Nummer",
      "Text",
      "Empfänger E-Mail",
      "Empfänger Adresse",
      "Verschickt am",
      "Fällig am",
      "Betrag",
      "MwSt.",
      "Rechnungsbetrag",
      "Bezahlt",
      "Kostenstellen",
      "Konten",
      "Zahlungseingänge",
      "Empfänger Firmenname",
      "Empfänger Name",
      "Empfänger zusätz. Adresszeile",
      "Empfänger Strasse",
      "Empfänger Hausnummer",
      "Empfänger Postfach",
      "Empfänger PLZ",
      "Empfänger Ort",
      "Empfänger Land",
      "Zahlungsempfänger Name",
      "Zahlungsempfänger Strasse",
      "Zahlungsempfänger Hausnummer",
      "Zahlungsempfänger PLZ",
      "Zahlungsempfänger Ort",
      "Zahlungsempfänger Land"]
  end
end
