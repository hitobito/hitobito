#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::Filter do
  let(:invoice) { invoices(:invoice) }
  let(:today)   { Time.zone.parse("2019-12-16 10:00:00") }

  around do |example|
    travel_to(today) do
      Invoice.update_all(created_at: 2.months.ago)
      example.call
    end
  end

  it "filters by year" do
    invoice.update(issued_at: 1.year.ago)
    filtered = Invoice::Filter.new(year: today.last_year.year).apply(Invoice)
    expect(filtered.count).to eq 1
  end

  it "filters by invoice_list_id" do
    invoice.update(invoice_list_id: 1)
    filtered = Invoice::Filter.new(invoice_list_id: 1).apply(Invoice)
    expect(filtered.count).to eq 1
  end
end
