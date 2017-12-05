# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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

  it 'validates that at least one email or an address is specified if no recipient' do
    invoice = Invoice.create(title: 'invoice', group: group)
    expect(invoice).not_to be_valid
    expect(invoice.errors.full_messages).to include('Address oder Email muss ausgefüllt werden')
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

  it '#recipients loads people from recipient_ids' do
    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.recipient_ids = "2,b,#{person.id},c,"
    expect(invoice.recipients).to eq [person]
  end

  it '#multi_create creates invoices for multiple recipients' do
    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.recipient_ids = [person.id, other_person.id].join(',')
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)
    invoice.invoice_items.build(name: 'pins', unit_cost: 0.5, count: 2)

    expect do
      invoice.multi_create
    end.to change { [group.invoices.count, group.invoice_items.count] }.by([2,4])
  end

  it '#multi_create does rollsback if any save fails' do
    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.recipient_ids = [person.id, other_person.id].join(',')
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)

    allow_any_instance_of(Invoice).to receive(:save).and_wrap_original do |m|
      @saved = @saved ? false  : m.call
    end

    expect do
      invoice.multi_create
    end.not_to change { [group.invoices.count, group.invoice_items.count] }
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

  context '#remindable?' do
    %w(sent overdue reminded).each do |state|
      it "#{state} invoice is remindable" do
        expect(Invoice.new(state: state)).to be_remindable
      end
    end
    %w(draft payed cancelled).each do |state|
      it "#{state} invoice is not remindable" do
        expect(Invoice.new(state: state)).not_to be_remindable
      end
    end
  end

  it 'knows a filename for the invoice-pdf' do
    invoice = create_invoice
    expect(invoice.sequence_number).to eq '834963567-1'
    expect(invoice.filename).to eq 'Rechnung-834963567-1.pdf'
  end

  it '.to_contactable' do
    expect(contactables(recipient_address: 'test')).to have(1).item
    expect(contactables(recipient_address: 'test').first.address).to eq 'test'
    expect(contactables({})).to be_empty
    expect(contactables({}, { recipient_address: 'test' })).to have(1).item
  end

  private

  def contactables(*args)
    invoices = args.collect { |attrs| Invoice.new(attrs) }
    Invoice.to_contactables(invoices)
  end

  def create_invoice(attrs = {})
    Invoice.create!(attrs.merge(title: 'invoice', group: group, recipient: person))
  end

end
