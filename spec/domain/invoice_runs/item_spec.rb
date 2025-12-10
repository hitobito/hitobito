# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceRuns::Item do
  let(:attrs) { {fee: :membership, key: :members, unit_cost: 10, layer_group_ids: nil} }

  subject(:item) { described_class.new(**attrs) }

  describe "with models" do
    subject(:invoice_item) { item.to_invoice_item }

    before { allow(item).to receive(:models).and_return(people(:top_leader, :bottom_member)) }

    it "uses models for counts, presence and total_cost" do
      expect(item.count).to eq 2
      expect(item).to be_present
      expect(item.total_cost).to eq 20
    end

    it "can build invoice item" do
      expect(invoice_item).to be_kind_of(InvoiceItem::FixedFee)
      expect(invoice_item.unit_cost).to eq 10
      expect(invoice_item.count).to eq 2
      expect(invoice_item.cost).to eq 20
      expect(invoice_item.dynamic_cost_parameters[:fixed_fees]).to eq :membership
      expect(invoice_item.read_attribute(:name)).to eq "members"
      expect(invoice_item.name).to eq "Mitgliedsbeitrag - Members"
    end
  end

  it "is not present with empty count" do
    allow(item).to receive(:models).and_return(Role.none)
    expect(item).not_to be_present
    expect(item.count).to eq 0
    expect(item.total_cost).to eq 0
  end
end
