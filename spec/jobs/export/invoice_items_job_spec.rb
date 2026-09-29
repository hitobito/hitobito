# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::InvoiceItemsJob do
  subject(:job) { described_class.new(format, user.id, invoice_ids, filename: "rechnungsposten") }

  let(:format) { :csv }
  let(:group) { groups(:top_group) }
  let(:user) { people(:top_leader) }

  let(:invoices) do
    3.times.map do
      Fabricate(:invoice, group: group, recipient: user).tap do |invoice|
        2.times { |i| Fabricate(:invoice_item, invoice: invoice, name: "Item #{i}") }
      end
    end
  end
  let(:invoice_ids) { invoices.map(&:id).shuffle }

  before { job.enqueue! }

  it "reports progress" do
    expect(described_class.reports_progress).to eq true
  end

  it "does not support pdf" do
    expect(described_class.new(:pdf, user.id, invoice_ids, {}).format_supported?).to eq false
    expect(described_class.new(:csv, user.id, invoice_ids, {}).format_supported?).to eq true
    expect(described_class.new(:xlsx, user.id, invoice_ids, {}).format_supported?).to eq true
  end

  it "exports the items of all invoices, grouped by invoice" do
    expect(Export::Tabular::InvoiceItems::List).to receive(:csv) do |entries|
      expect(entries.map(&:invoice_id)).to eq invoice_ids.sort.flat_map { |id| [id, id] }
    end
    job.perform
  end

  it "loads the invoice of every item without an extra query per item" do
    entries = job.entries.to_a
    expect(entries.size).to eq 6
    expect(entries.map { |entry| entry.association(:invoice).loaded? }).to all(be true)
  end

  context "xlsx" do
    let(:format) { :xlsx }

    it "exports tabular xlsx" do
      expect(Export::Tabular::InvoiceItems::List).to receive(:xlsx)
      job.perform
    end
  end

  context "without any invoice" do
    let(:invoice_ids) { [] }

    it "does nothing" do
      expect(Export::Tabular::InvoiceItems::List).not_to receive(:csv)
      expect(job.data).to be_nil
      expect(job.entries.to_a).to eq []
    end
  end
end
