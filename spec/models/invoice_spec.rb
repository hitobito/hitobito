require 'spec_helper'

describe Invoice do
  let(:group)          { groups(:top_layer) }
  let(:person)         { people(:top_leader) }
  let(:other_person)   { people(:bottom_member) }
  let(:invoice_config) { group.invoice_config }

  it 'saving requires group, title and recipient' do
    invoice = create_invoice
    expect(invoice).to be_valid
    expect(invoice.state).to eq 'draft'
  end

  it 'saving increments number on invoice_config' do
    expect do
      2.times { create_invoice }
    end.to change { invoice_config.reload.sequence_number }.by(2)
  end

  it 'computes sequence_number based of group_id and invoice_config.sequence_number' do
    expect(create_invoice.sequence_number).to eq "#{group.id}-1"
  end

  it 'computes esr_number based of group_id and invoice_config.sequence_number' do
    expect(create_invoice.esr_number).to eq "#{group.id}-1"
  end

  it '#save sets recipient and related fields' do
    invoice = create_invoice
    expect(invoice.recipient).to eq person
    expect(invoice.recipient_email).to eq person.email
    expect(invoice.recipient_address).to eq "Top Leader\nSupertown"
  end

  it '#save calcuates total for invoices at once' do
    invoice = Invoice.new(title: 'invoice', group: group, recipient: person)
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)
    invoice.invoice_items.build(name: 'pins', unit_cost: 0.5, count: 2)
    expect { invoice.save! }.to change { InvoiceItem.count }.by(2)
    expect(invoice.total).to eq 2.5
  end

  it '#recalculate must be called when invoice item is added' do
    invoice = Invoice.create!(group: group, title: :title, recipient: person)
    expect(invoice.total).to eq(0)
    invoice.invoice_items.create!(name: 'pens', unit_cost: 1.5)
    invoice.recalculate
    expect(invoice.total).to eq(1.5)
  end

  it '#multi_create creates invoices for multiple recipients' do
    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)
    invoice.invoice_items.build(name: 'pins', unit_cost: 0.5, count: 2)

    expect do
      invoice.multi_create([person, other_person])
    end.to change { [group.invoices.count, group.invoice_items.count] }.by([2,4])
  end

  it '#to_s returns total amount' do
    invoice = invoices(:invoice)
    expect(invoice.to_s).to eq "Invoice(#{invoice.sequence_number}): 2.0"
  end

  it '#calculated returns summed fields of invoice_items' do
    calculated = invoices(:invoice).calculated
    expect(calculated[:total]).to eq 5.0036
    expect(calculated[:cost]).to eq 5.0
    expect(calculated[:vat]).to eq 0.0036
  end

  it 'changing state to sent sets sent_at and due_at dates' do
    invoice = create_invoice
    now = Time.zone.parse('2017-09-18 14:00:00')
    Timecop.freeze now do
      expect do
        invoice.update(state: :sent)
      end.to change { [invoice.sent_at, invoice.due_at] }.to([
        now.to_date,
        now.to_date + 30.days
      ])
    end
  end

  private

  def create_invoice(attrs = {})
    Invoice.create!(attrs.merge(title: 'invoice', group: group, recipient: person))
  end

end
