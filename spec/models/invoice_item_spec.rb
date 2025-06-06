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
#  index_invoice_items_on_invoice_id  (invoice_id)
#
require "spec_helper"

describe InvoiceItem do
  let(:invoice) { invoices(:invoice) }

  class InvoiceItem::NilCostDynamic < ::InvoiceItem
    self.dynamic = true

    def dynamic_cost
      nil
    end
  end

  it "can calculate total, cost and vat" do
    item = InvoiceItem.new(invoice: invoice,
      name: :pens,
      count: 3,
      unit_cost: 1,
      vat_rate: 4)

    expect(item.total).to eq 3.12
    expect(item.cost).to eq 3
    expect(item.vat).to eq 0.12
  end

  it "calculates with 1 as default count" do
    item = InvoiceItem.new(invoice: invoice,
      name: :pens,
      unit_cost: 1,
      vat_rate: 4)
    expect(item.total).to eq 1.04
    expect(item.cost).to eq 1
    expect(item.vat).to eq 0.04
  end

  it "calculates without vat if vat_rate is missing" do
    item = InvoiceItem.new(invoice: invoice,
      name: :pens,
      unit_cost: 1)
    expect(item.total).to eq 1
    expect(item.cost).to eq 1
    expect(item.vat).to eq 0
  end

  it "calculates to 0 if unit_cost is 0" do
    item = InvoiceItem.new(invoice: invoice,
      name: :pens,
      unit_cost: 0)
    expect(item.total).to eq 0
    expect(item.cost).to eq 0
    expect(item.vat).to eq 0
  end

  it "calculates to 0 if unit_cost is nil" do
    item = InvoiceItem.new(invoice: invoice,
      name: :pens,
      unit_cost: nil)
    expect(item.total).to eq 0
    expect(item.cost).to eq 0
    expect(item.vat).to eq 0
  end

  it "calculates to 0 if count is nil" do
    item = InvoiceItem.new(invoice: invoice,
      name: :pens,
      unit_cost: 1,
      count: nil)
    expect(item.total).to eq 0
    expect(item.cost).to eq 0
    expect(item.vat).to eq 0
  end

  describe "recalculating" do
    let(:new_invoice) do
      Fabricate(:invoice, group: invoice.group, recipient: people(:bottom_member),
        invoice_items_attributes: {
          "0" => {
            name: :pens,
            count: 1,
            unit_cost: 10
          }
        })
    end
    let(:item) { new_invoice.invoice_items.first }

    it "recalculates invoice after update count" do
      expect {
        item.update!(count: 2)
        new_invoice.reload
      }.to change { new_invoice.total }.from(10).to(20)
    end

    it "recalculates invoice after update unit_cost" do
      expect {
        item.update!(unit_cost: 20)
        new_invoice.reload
      }.to change { new_invoice.total }.from(10).to(20)
    end

    it "does not recalculate invoice after update name" do
      expect {
        item.update!(name: :utensils)
        new_invoice.reload
      }.to change { new_invoice.attributes }
    end

    it "recalculates invoice list" do
      invoice_list = InvoiceList.create!(group: invoice.group, title: new_invoice.title)
      new_invoice.update!(invoice_list: invoice_list)
      invoice_list.update_total
      expect {
        item.update!(unit_cost: 20)
        invoice_list.reload
      }.to change { invoice_list.amount_total }.from(10).to(20)
    end
  end

  context "dynamic invoice item" do
    it "returns nil vat for nil dynamic cost" do
      new_invoice = Fabricate(:invoice, group: invoice.group, recipient: people(:bottom_member),
        invoice_items_attributes: {
          "0" => {
            name: :pens,
            count: 1,
            unit_cost: 0,
            vat_rate: 10,
            type: "InvoiceItem::NilCostDynamic"
          }
        })

      item = new_invoice.invoice_items.first

      expect(item.vat).to be_nil
    end

    it "returns nil total for nil dynamic cost" do
      new_invoice = Fabricate(:invoice, group: invoice.group, recipient: people(:bottom_member),
        invoice_items_attributes: {
          "0" => {
            name: :pens,
            count: 1,
            unit_cost: 0,
            vat_rate: 10,
            type: "InvoiceItem::NilCostDynamic"
          }
        })

      item = new_invoice.invoice_items.first

      expect(item.total).to be_nil
    end
  end
end
