# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.


require "spec_helper"

describe Invoice::BatchCreate do
  include ActiveJob::TestHelper

  let(:mailing_list) { mailing_lists(:leaders) }
  let(:group)        { groups(:top_layer) }
  let(:person)       { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }

  it "#call creates invoices for abo" do
    Subscription.create!(mailing_list: mailing_list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])

    list = InvoiceList.new(receiver: mailing_list, group: group, title: :title)

    invoice = Invoice.new(title: "invoice", group: group)
    invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
    invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
    list.invoice = invoice

    expect do
      Invoice::BatchCreate.call(list)
    end.to change { [group.invoices.count, group.invoice_items.count] }.by([1, 2])
    expect(list.reload).to have(1).invoices
    expect(list.receiver).to eq mailing_list
    expect(list.recipients_total).to eq 1
    expect(list.recipients_paid).to eq 0
    expect(list.amount_total).to eq 2.5
    expect(list.amount_paid).to eq 0
  end

  it "#call offloads to job when recipients exceed limit" do
    Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group))
    Subscription.create!(mailing_list: mailing_list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])

    list = InvoiceList.new(receiver: mailing_list, group: group, title: :title)

    invoice = Invoice.new(title: "invoice", group: group)
    invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
    invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
    list.invoice = invoice

    expect do
      Invoice::BatchCreate.call(list, 1)
      Delayed::Job.last.payload_object.perform
    end.to change { [group.invoices.count, group.invoice_items.count] }.by([2, 4])
    expect(list.reload).to have(2).invoices
    expect(list.receiver).to eq mailing_list
    expect(list.recipients_total).to eq 2
    expect(list.recipients_paid).to eq 0
    expect(list.amount_total).to eq 5
    expect(list.amount_paid).to eq 0
    expect(list.recipients_processed).to eq 2
  end

  it "#call does not create any list model for recipient_ids" do
    list = InvoiceList.new(group: group)
    list.recipient_ids = [person.id, other_person.id].join(",")

    invoice = Invoice.new(title: "invoice", group: group)
    invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
    invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
    list.invoice = invoice

    expect do
      Invoice::BatchCreate.call(list)
    end.to change { [group.invoices.count, group.invoice_items.count] }.by([2, 4])
    expect(list).not_to be_persisted
  end

  it "#call does not rollback if any save fails" do
    Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group))
    Subscription.create!(mailing_list: mailing_list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])

    list = InvoiceList.new(receiver: mailing_list, group: group, title: :title)
    invoice = Invoice.new(title: "invoice", group: group)
    invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
    list.invoice = invoice

    allow_any_instance_of(Invoice).to receive(:save).and_wrap_original do |m|
      @saved = @saved ? false : m.call
    end

    expect do
      Invoice::BatchCreate.new(list).call
    end.to change { [group.invoices.count, group.invoice_items.count] }.by([1, 1])
    expect((list.invalid_recipient_ids)).to have(1).item
  end
end
