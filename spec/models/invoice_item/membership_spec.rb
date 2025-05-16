# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceItem::Membership do
  before do
    allow(Settings).to receive_message_chain(:invoices, :membership, :recipient, :roles).and_return(%w[
      Group::BottomLayer::Leader
      Group::BottomGroup::Leader
    ])
  end

  let(:member_fee) { {unit_cost: 10, name: :members, roles: %w[Group::BottomGroup::Member Group::BottomLayer::Member]} }

  describe "#calculate_amount" do
    subject(:item) { described_class.new(dynamic_cost_parameters: member_fee) }

    it "is 1 as fixtures member matches " do
      expect(item.calculate_amount).to eq 1
    end

    it "counts other member roles" do
      Fabricate(Group::BottomLayer::Member.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Member.sti_name, group: groups(:bottom_group_two_one))
      expect(item.calculate_amount).to eq 3
    end

    it "counts only roles from specific layer derrived from recipient" do
      Fabricate(Group::BottomLayer::Member.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Member.sti_name, group: groups(:bottom_group_two_one))
      layer_one = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      layer_two = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_two))
      expect(item.calculate_amount(recipient: layer_one)).to eq 2
      expect(item.calculate_amount(recipient: layer_two)).to eq 1
    end
  end
end
