# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Sheet::Invoice do
  let(:invoice) { Fabricate.build(:invoice, title: "Testrechnung") }

  it "uses Rechnungen as title if on list" do
    sheet = Sheet::Invoice.new(self)
    expect(sheet.title).to eq "Rechnungen"
  end

  it "uses Rechnungen as title with invoice" do
    sheet = Sheet::Invoice.new(self, nil, invoice)
    expect(sheet.title).to eq "Rechnungen"
  end

  context "on list" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:mailing_list) { mailing_lists(:leaders) }

    let(:sheet) { Sheet::Invoice.new(self, invoice_run, invoice) }
    let(:invoice_run) {
      InvoiceRun.create(title: "Mitgliedsbeiträge", group_id: group.id, recipient_source: mailing_list)
    }

    it "uses title of invoice with recipient_source mailing_list" do
      view.params[:invoice_run_id] = invoice_run.id
      expect(sheet.title).to eq "Testrechnung - Leaders (Abo)"
    end

    it "uses title of invoice without recipient_source name when people_filter" do
      invoice_run.update!(recipient_source: PeopleFilter.new)
      view.params[:invoice_run_id] = invoice_run.id
      expect(sheet.title).to eq "Testrechnung"
    end
  end
end
