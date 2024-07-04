#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::Invoices::EvaluationRow do
  let(:row) do
    {name: "Membership", vat: 10, count: 2,
     amount_paid: 110, cost_center: "Members",
     account: "01-23456-7"}
  end

  subject { described_class.new(row) }

  it "exports values" do
    expect(subject.fetch(:name)).to eq("Membership")
    expect(subject.fetch(:vat)).to eq("10.00")
    expect(subject.fetch(:count)).to eq(2)
    expect(subject.fetch(:amount_paid)).to eq("110.00")
    expect(subject.fetch(:cost_center)).to eq("Members")
    expect(subject.fetch(:account)).to eq("01-23456-7")
  end
end
