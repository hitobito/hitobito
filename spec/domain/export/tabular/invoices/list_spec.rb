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
                                      :payments,]

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
                                  "Total inkl. MwSt.",
                                  "Total bezahlt",
                                  "Kostenstellen",
                                  "Konten",
                                  "Zahlungseingänge",]
  end
end
