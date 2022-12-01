require 'spec_helper'

describe InvoiceItem do
  let(:invoice) { invoices(:invoice) }


  it 'can calculate total, cost and vat' do
    item = InvoiceItem.new(invoice: invoice,
                           name: :pens,
                           count: 3,
                           unit_cost: 1,
                           vat_rate: 4)

    expect(item.total).to eq 3.12
    expect(item.cost).to eq 3
    expect(item.vat).to eq 0.12
  end

  it 'calculates with 1 as default count' do
    item = InvoiceItem.new(invoice: invoice,
                           name: :pens,
                           unit_cost: 1,
                           vat_rate: 4)
    expect(item.total).to eq 1.04
    expect(item.cost).to eq 1
    expect(item.vat).to eq 0.04
  end

  it 'calculates without vat if vat_rate is missing' do
    item = InvoiceItem.new(invoice: invoice,
                           name: :pens,
                           unit_cost: 1)
    expect(item.total).to eq 1
    expect(item.cost).to eq 1
    expect(item.vat).to eq 0
  end

  it 'calculates to 0 if unit_cost is 0' do
    item = InvoiceItem.new(invoice: invoice,
                           name: :pens,
                           unit_cost: 0)
    expect(item.total).to eq 0
    expect(item.cost).to eq 0
    expect(item.vat).to eq 0
  end

  it 'calculates to 0 if unit_cost is nil' do
    item = InvoiceItem.new(invoice: invoice,
                           name: :pens,
                           unit_cost: nil)
    expect(item.total).to eq 0
    expect(item.cost).to eq 0
    expect(item.vat).to eq 0
  end

  it 'calculates to 0 if count is nil' do
    item = InvoiceItem.new(invoice: invoice,
                           name: :pens,
                           unit_cost: 1,
                           count: nil)
    expect(item.total).to eq 0
    expect(item.cost).to eq 0
    expect(item.vat).to eq 0
  end

  it 'recalculates invoice after update count' do
    new_invoice = Fabricate(:invoice, group: invoice.group, recipient: people(:bottom_member),
                            invoice_items_attributes: {
                              '0' => {
                                name: :pens,
                                count: 1,
                                unit_cost: 10
                              }
                            })

    item = new_invoice.invoice_items.first

    expect(new_invoice.total).to eq(10)

    item.update(count: 2)

    new_invoice.reload

    expect(new_invoice.total).to eq(20)
  end

  it 'recalculates invoice after update unit_cost' do
    new_invoice = Fabricate(:invoice, group: invoice.group, recipient: people(:bottom_member),
                            invoice_items_attributes: {
                              '0' => {
                                name: :pens,
                                count: 1,
                                unit_cost: 10
                              }
                            })

    item = new_invoice.invoice_items.first

    expect(new_invoice.total).to eq(10)

    item.update(unit_cost: 20)

    new_invoice.reload

    expect(new_invoice.total).to eq(20)
  end

  it 'does not recalculate invoice after update name' do
    new_invoice = Fabricate(:invoice, group: invoice.group, recipient: people(:bottom_member),
                            invoice_items_attributes: {
                              '0' => {
                                name: :pens,
                                count: 1,
                                unit_cost: 10
                              }
                            })

    item = new_invoice.invoice_items.first

    expect(new_invoice.total).to eq(10)

    expect do
      item.update(name: :utensils)
    end.to_not change { new_invoice.reload }
  end
end
