#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::Filter do
  let(:invoice) { invoices(:invoice) }
  let(:today) { Time.zone.parse("2019-12-16 10:00:00") }

  around do |example|
    travel_to(today) do
      Invoice.update_all(created_at: 2.months.ago)
      example.call
    end
  end

  it "filters by daterange" do
    invoice.update(issued_at: 1.year.ago)

    filtered = Invoice::Filter.new(
      from: today.last_year.beginning_of_year,
      to: today.last_year.end_of_year
    ).apply(Invoice)

    expect(filtered.count).to eq 1
  end

  it "filters by invoice_run_id" do
    invoice.update(invoice_run_id: 1)
    filtered = Invoice::Filter.new(invoice_run_id: 1).apply(Invoice)
    expect(filtered.count).to eq 1
  end

  it "does not filter by year for singular invoices" do
    invoice.update(issued_at: 5.year.ago)
    filtered = Invoice::Filter.new(ids: invoice.id, singular: true).apply(Invoice)
    expect(filtered.count).to eq 1
  end

  context "invoice type" do
    let(:template) { Fabricate(:period_invoice_template) }
    let(:plain_run) { Fabricate(:invoice_run, group: invoice.group) }

    let(:template_run) do
      Fabricate(:invoice_run, group: invoice.group, recipient_source: template.recipient_source,
        period_invoice_template: template)
    end

    let!(:from_plain_run_invoice) do
      Fabricate(:invoice, group: invoice.group, invoice_run: plain_run)
    end

    let!(:from_template_run_invoice) do
      Fabricate(:invoice, group: invoice.group, invoice_run: template_run)
    end

    it "shows all invoices when every type is selected" do
      filtered = Invoice::Filter.new(
        standalone: "1", from_standalone_invoice_run: "1", from_template_invoice_run: "1"
      ).apply(Invoice)
      expect(filtered).to include(invoice, from_plain_run_invoice, from_template_run_invoice)
    end

    it "only shows standalone invoices when only standalone is selected" do
      filtered = Invoice::Filter.new(
        standalone: "1", from_standalone_invoice_run: "0", from_template_invoice_run: "0"
      ).apply(Invoice)
      expect(filtered).to include invoice
      expect(filtered).not_to include(from_plain_run_invoice, from_template_run_invoice)
    end

    it "combines standalone and from_standalone_invoice_run, excluding from_template_invoice_run" do
      filtered = Invoice::Filter.new(
        standalone: "1", from_standalone_invoice_run: "1", from_template_invoice_run: "0"
      ).apply(Invoice)
      expect(filtered).to include(invoice, from_plain_run_invoice)
      expect(filtered).not_to include from_template_run_invoice
    end

    it "shows nothing when every type is deselected" do
      filtered = Invoice::Filter.new(
        standalone: "0", from_standalone_invoice_run: "0", from_template_invoice_run: "0"
      ).apply(Invoice)
      expect(filtered).to be_empty
    end

    it "does not restrict by type when no type params are given" do
      filtered = Invoice::Filter.new.apply(Invoice.all)
      expect(filtered).to include(invoice, from_plain_run_invoice, from_template_run_invoice)
    end

    it "combines invoice_run_id with invoice type without dropping the invoice_run_id restriction" do
      filtered = Invoice::Filter.new(
        invoice_run_id: plain_run.id,
        standalone: "1", from_standalone_invoice_run: "1", from_template_invoice_run: "1"
      ).apply(Invoice)
      expect(filtered).to include from_plain_run_invoice
      expect(filtered).not_to include(invoice, from_template_run_invoice)
    end
  end
end
