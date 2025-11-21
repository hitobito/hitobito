# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceRuns::RoleItem do
  let(:attrs) {
    {fee: :membership, key: :members, unit_cost: 10, roles: [
      Group::BottomLayer::Member.sti_name
    ]}
  }

  subject(:item) { described_class.new(**attrs) }

  it "#to_invoice_item has translated name and key for fixed fees" do
    expect(item.to_invoice_item.name).to eq "Mitgliedsbeitrag - Members"
    expect(item.to_invoice_item.dynamic_cost_parameters[:fixed_fees]).to eq :membership
  end

  describe "#models" do
    it "finds only configured models" do
      expect(item.models).to eq [roles(:bottom_member)]
    end

    it "includes models inside layer" do
      item = described_class.new(**attrs.merge(layer_group_ids: [groups(:bottom_layer_one).id]))
      expect(item.models).to eq [roles(:bottom_member)]
    end

    it "exludes models outside of layer" do
      item = described_class.new(**attrs.merge(layer_group_ids: [groups(:bottom_layer_two).id]))
      expect(item.models).to be_empty
    end
  end
end
