#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::Invoices::EvaluationList do
  let(:list) do
    Export::Tabular::Invoices::EvaluationList.new([{name: "Membership", vat: 10, count: 2,
                                                    amount_paid: 10, cost_center: "Members",
                                                    account: "01-23456-7"}])
  end

  subject { list }

  it "uses certain attributes with tranlsations" do
    expect(subject.attributes).to eq [:name, :vat, :count, :amount_paid, :account, :cost_center]

    expect(subject.labels).to eq ["Produktbezeichnung",
      "MwSt.",
      "Anzahl",
      "Betrag bezahlt",
      "Konto",
      "Kostenstelle"]
  end
end
