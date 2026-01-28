# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::InvoicesJob do
  subject { described_class.new(format, user.id, invoice_ids, filename: filename) }

  let(:filename) { AsyncDownloadFile.create_name("rechnungen", user.id) }
  let(:pdf) { AsyncDownloadFile.from_filename(filename, format) }

  let(:group) { groups(:top_group) }
  let(:user) { people(:top_leader) }
  let(:invoice_ids) do
    3.times.map do
      Fabricate(:invoice, group: group, recipient: user).id
    end.shuffle
  end

  let(:invoices_in_order) do
    invoice_ids.map { |id| Invoice.find(id) }
  end

  context "creates a PDF export, it" do
    let(:format) { :pdf }

    it "calls render_multiple with invoices in the same order as invoice_ids" do
      expect(Export::Pdf::Invoice).to receive(:render_multiple).with(invoices_in_order, anything)
      subject.perform
    end
  end

  context "creates a CSV export, it" do
    let(:format) { :csv }

    it "export tabular CSV with invoices in the same order as invoice_ids" do
      expect(Export::Tabular::Invoices::List).to receive(:csv).with(invoices_in_order)
      subject.perform
    end
  end
end
