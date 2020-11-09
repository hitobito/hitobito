# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe InvoiceList do
  let(:list)         { mailing_lists(:leaders) }
  let(:group)        { groups(:top_layer) }
  let(:person)       { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }

  it 'accepts recipient_ids as comma-separates values' do
    subject.attributes = { recipient_ids: "#{person.id},#{other_person.id}" }
    expect(subject.recipient_ids_count).to eq 2
    expect(subject.first_recipient).to eq person
  end

  it 'accepts receiver as id and type' do
    Subscription.create!(mailing_list: list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])
    subject.attributes = { receiver_type: 'MailingList', receiver_id: list.id }
    expect(subject.recipient_ids_count).to eq 1
    expect(subject.first_recipient).to eq person
  end

  it '#multi_create creates invoices for abo' do
    subject.receiver = list
    Subscription.create!(mailing_list: list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])
    subject.group = group

    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)
    invoice.invoice_items.build(name: 'pins', unit_cost: 0.5, count: 2)
    subject.invoice = invoice

    expect do
      subject.multi_create
    end.to change { [group.invoices.count, group.invoice_items.count] }.by([1, 2])
    expect(subject.reload).to have(1).invoices
    expect(subject.receiver).to eq list
  end

  it '#multi_create creates invoices for multiple recipients' do
    subject.recipient_ids = [person.id, other_person.id].join(',')
    subject.group = group

    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)
    invoice.invoice_items.build(name: 'pins', unit_cost: 0.5, count: 2)
    subject.invoice = invoice

    expect do
      subject.multi_create
    end.to change { [group.invoices.count, group.invoice_items.count] }.by([2, 4])
    expect(subject.reload).to have(2).invoices

    expect(subject.receiver_type).to be_nil
    expect(subject.recipients_total).to eq 2
    expect(subject.recipients_paid).to eq 0
    expect(subject.amount_total).to eq 5
    expect(subject.amount_paid).to eq 0
  end

  it '#multi_create does rollsback if any save fails' do
    subject.recipient_ids = [person.id, other_person.id].join(',')
    subject.group = group

    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)
    subject.invoice = invoice

    allow_any_instance_of(Invoice).to receive(:save).and_wrap_original do |m|
      @saved = @saved ? false : m.call
    end

    expect do
      subject.multi_create
    end.not_to change { [group.invoices.count, group.invoice_items.count] }
  end
end

