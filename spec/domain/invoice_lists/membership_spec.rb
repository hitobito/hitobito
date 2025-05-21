# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceLists::Membership do
  describe "::warning" do
    subject(:warning) { InvoiceLists::Membership.warning }

    it "is nil if all groups have a configured recipient" do
      Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_two_one))
      expect(warning).to be_nil
    end

    it "lists groups where no recipient was found" do
      Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      expect(warning).to eq "Für folgende Gruppen konnte kein Empfänger ermittelt werden: Bottom Two"
    end
  end

  describe "::recipient_ids" do
    subject(:recipient_ids) { InvoiceLists::Membership.recipient_ids(2025) }

    it "is empty if no roles match" do
      expect(recipient_ids).to be_empty
    end

    it "finds layer leader" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      expect(recipient_ids).to eq([role.person_id])
    end

    it "finds group leader" do
      role = Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one))
      expect(recipient_ids).to eq([role.person_id])
    end

    it "finds preferred role if two roles match for different people in single layer" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one))
      expect(recipient_ids).to eq([role.person_id])
    end

    it "finds preferred role if two roles match for single person in layer" do
      preferred = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one), person: preferred.person)
      expect(recipient_ids).to eq([preferred.person_id])
    end

    it "finds two roles for single person if they are on distinct layers" do
      one = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      two = Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_two_one), person: one.person)
      expect(recipient_ids).to match_array([one, two].map(&:person_id))
    end

    it "finds leaders if single role has not been billed for that year" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      InvoiceItemRole.create!(invoice_item_id: 1, role: role, layer_group_id: role.group.layer_group_id, year: 2025)
      expect(recipient_ids).to eq([role.person_id])
    end

    it "is empty if both roles have already been billed for that year" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_two))
      InvoiceItemRole.create!(invoice_item_id: 1, role: roles(:bottom_member), layer_group_id: groups(:bottom_layer_one).id, year: 2025)
      InvoiceItemRole.create!(invoice_item_id: 1, role: role, layer_group_id: role.group.layer_group_id, year: 2025)
      expect(recipient_ids).to eq([])
    end

    it "finds leader again if both roles have been billed for previous but not current year" do
      role = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_two))
      InvoiceItemRole.create!(invoice_item_id: 1, role: roles(:bottom_member), layer_group_id: groups(:bottom_layer_one).id, year: 2024)
      InvoiceItemRole.create!(invoice_item_id: 1, role: role, layer_group_id: role.group.layer_group_id, year: 2024)
      expect(recipient_ids).to eq([role.person_id])
    end
  end

  describe "::invoice_items" do
    subject(:invoice_items) { InvoiceLists::Membership.build_invoice_items }

    it "is empty when nothing is configured" do
      allow(Settings).to receive_message_chain(:invoices, :membership, :fees).and_return([])
      expect(invoice_items).to be_empty
    end

    context "when configured" do
      it "builds from configuration settings" do
        expect(invoice_items).to have(2).item
        expect(invoice_items.first.attributes.compact.symbolize_keys).to eq(
          count: 1,
          unit_cost: 10,
          type: "InvoiceItem::Membership",
          name: "Mitgliedsbeitrag - Members",
          dynamic_cost_parameters: {
            fixed_fees: :memberships, name: :members, roles: ["Group::BottomGroup::Member", "Group::BottomLayer::Member"], unit_cost: 10
          }
        )
        expect(invoice_items.last.attributes.compact.symbolize_keys).to eq(
          count: 1,
          unit_cost: 15,
          type: "InvoiceItem::Membership",
          name: "Mitgliedsbeitrag - Leaders",
          dynamic_cost_parameters: {
            fixed_fees: :memberships, name: :leaders, roles: ["Group::BottomGroup::Leader", "Group::BottomLayer::Leader"], unit_cost: 15
          }
        )
      end
    end
  end

  describe "::prepare" do
    let(:invoice) { Invoice.new }

    subject(:list) { InvoiceList.new(invoice: invoice) }

    before do
      Fabricate(Group::BottomLayer::Member.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Member.sti_name, group: groups(:bottom_group_two_one))
      Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_two))
    end

    it "populates without calculating invoice" do
      described_class.prepare(list, calculate: false)
      expect(list.invoice.issued_at).to eq Time.zone.today
      expect(invoice.invoice_items).to have(2).items
      members, leaders = invoice.invoice_items
      expect(members.count).to eq(1)
      expect(leaders.count).to eq(1)
      expect(members.cost).to be_nil
      expect(members.cost).to be_nil
    end

    it "populates and calculates invoice" do
      described_class.prepare(list, calculate: true)
      expect(list.invoice.issued_at).to eq Time.zone.today
      expect(invoice.invoice_items).to have(2).items
      members, leaders = invoice.invoice_items
      expect(members.count).to eq(3)
      expect(members.cost).to eq(30)
      expect(leaders.count).to eq(2)
      expect(members.cost).to eq(30)
    end
  end
end
