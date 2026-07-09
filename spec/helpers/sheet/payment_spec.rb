# frozen_string_literal: true

#  Copyright (c) 2026-2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Sheet::Payment do
  let(:payment) { Fabricate.build(:payment) }

  it "has a title if on list" do
    sheet = Sheet::Payment.new(self)
    expect(sheet.title).to eq "Zahlungen"
  end

  it "has a title with payment" do
    sheet = Sheet::Payment.new(self, nil, payment)
    expect(sheet.title).to eq "Zahlungen"
  end

  it "renders a left nav" do
    sheet = Sheet::Payment.new(self)
    expect(sheet.left_nav?).to eq true
  end

  context "on list" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:invoice) { Fabricate.create(:invoice, group: group) }
    let(:sheet) { Sheet::Payment.new(self, nil, payment) }

    it "uses Sheet::Group as parent by default" do
      expect(sheet.parent_sheet).to be_a(Sheet::Group)
    end

    it "uses Sheet::Invoice as parent when nested in invoice" do
      view.params[:invoice_id] = invoice.id
      expect(sheet.parent_sheet).to be_a(Sheet::Invoice)
    end
  end
end
