# frozen_string_literal: true

# == Schema Information
#
# Table name: invoice_items
#
#  id                      :integer          not null, primary key
#  account                 :string
#  cost                    :decimal(12, 2)
#  cost_center             :string
#  count                   :integer          default(1), not null
#  description             :text
#  dynamic_cost_parameters :text
#  name                    :string           not null
#  type                    :string           default("InvoiceItem"), not null
#  unit_cost               :decimal(12, 2)   not null
#  vat_rate                :decimal(5, 2)
#  invoice_id              :integer          not null
#
# Indexes
#
#  index_invoice_items_on_invoice_id    (invoice_id)
#  invoice_items_search_column_gin_idx  (search_column) USING gin
#

require "spec_helper"

describe InvoiceItem::Membership do
  before do
    # TODO how to verfiy locale is used correctly
    allow(I18n).to receive(:t).with(:members, scope: :"invoice_item/membership", locale: nil).and_return("Mitgliedsbeitrag")
  end

  let(:invoice) { Invoice.new(issued_at: Date.new(2025, 5, 19), id: 1) }
  let(:member_fee) { Settings.invoices.membership.fees.first.to_h }

  subject(:item) { described_class.new(dynamic_cost_parameters: member_fee, invoice: invoice) }

  it "translates name" do
    expect(item.name).to eq "Mitgliedsbeitrag"
  end

  describe "#roles_scope" do
    let(:bottom_member) { roles(:bottom_member) }
    let(:layer_one_id) { groups(:bottom_layer_one).id }

    it "finds single role" do
      expect(item.roles_scope).to have(1).item
    end

    it "finds nothing for layer where no role exists" do
      expect(item.roles_scope(layer_group_id: groups(:bottom_layer_two).id)).to be_empty
      expect(item.dynamic_cost_parameters[:role_ids]).to eq []
    end

    it "finds role for layer where role exists" do
      expect(item.roles_scope(layer_group_id: layer_one_id)).to eq [bottom_member]
      expect(item.dynamic_cost_parameters[:role_ids]).to eq [bottom_member.id]
    end

    it "finds role for layer where role exists if marked for other year" do
      InvoiceItemRole.create!(year: 2024, role_id: bottom_member.id, invoice_item_id: 1, layer_group_id: layer_one_id)
      expect(item.roles_scope(layer_group_id: layer_one_id)).to eq [bottom_member]
      expect(item.dynamic_cost_parameters[:role_ids]).to eq [bottom_member.id]
    end

    it "no longer finds role for layer where role exists if role when marked for invoice year" do
      InvoiceItemRole.create!(year: 2025, role_id: bottom_member.id, invoice_item_id: 1, layer_group_id: layer_one_id)
      expect(item.roles_scope(layer_group_id: layer_one_id)).to be_empty
      expect(item.dynamic_cost_parameters[:role_ids]).to be_empty
    end
  end

  describe "#calculate_amount" do
    it "counts single member" do
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
      Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_two))
      expect(item.calculate_amount(groups(:bottom_layer_one))).to eq 2
      expect(item.calculate_amount(groups(:bottom_layer_two))).to eq 1
    end
  end
end
