# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.


require 'spec_helper'

describe Invoice::BatchCreate do
  include ActiveJob::TestHelper

  let(:mailing_list) { mailing_lists(:leaders) }
  let(:group)        { groups(:top_layer) }
  let(:person)       { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }

  it '#call creates invoices for abo' do
    Subscription.create!(mailing_list: mailing_list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])

    list = InvoiceList.new(receiver: mailing_list, group: group, title: :title)

    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)
    invoice.invoice_items.build(name: 'pins', unit_cost: 0.5, count: 2)
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

  it '#call creates invoices for abo with variable donation amount' do
    Subscription.create!(mailing_list: mailing_list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])

    list = InvoiceList.new(receiver: mailing_list, group: group, title: :title)

    group.invoice_config.update!(donation_increase_percentage: 5, donation_calculation_year_amount: 2)

    fabricate_donation(50, 1.year.ago)
    fabricate_donation(150, 2.years.ago)
    fabricate_donation(2000, 2.years.ago)
    fabricate_donation(300, 2.years.ago)
    fabricate_donation(100, 2.years.ago)

    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)
    invoice.invoice_items.build(name: 'variable donation', unit_cost: 0, variable_donation: true)
    list.invoice = invoice

    Invoice::BatchCreate.call(list)

    expect(list.reload).to have(1).invoices
    expect(list.receiver).to eq mailing_list
    expect(list.recipients_total).to eq 1
    expect(list.recipients_paid).to eq 0
    
    # median amount is 150, raise by 5%: 150 * 1.05 = 157.5, add other invoice_item: 157.5 + 1.5 = 159
    expect(list.amount_total).to eq 159
    expect(list.amount_paid).to eq 0
  end

  it '#call deletes invoice if variable donation with amount 0 is the only invoice item' do
    Subscription.create!(mailing_list: mailing_list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])

    list = InvoiceList.new(receiver: mailing_list, group: group, title: :title)

    group.invoice_config.update!(donation_increase_percentage: 5, donation_calculation_year_amount: 2)

    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.invoice_items.build(name: 'variable donation', unit_cost: 0, variable_donation: true)
    list.invoice = invoice

    Invoice::BatchCreate.call(list)

    expect(list.reload).to have(0).invoices
    expect(list.receiver).to eq mailing_list
  end

  it '#call deletes variable donation invoice item with amount 0' do
    Subscription.create!(mailing_list: mailing_list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])

    list = InvoiceList.new(receiver: mailing_list, group: group, title: :title)

    group.invoice_config.update!(donation_increase_percentage: 5, donation_calculation_year_amount: 2)

    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.invoice_items.build(name: 'pens', unit_cost: 15.5)
    invoice.invoice_items.build(name: 'variable donation', unit_cost: 0, variable_donation: true)
    list.invoice = invoice

    expect do
      Invoice::BatchCreate.call(list)
    end.to change { group.invoice_items.count }.by(1)

    expect(list.reload).to have(1).invoices
    expect(list.receiver).to eq mailing_list
    expect(list.recipients_total).to eq 1
    expect(list.recipients_paid).to eq 0
    
    expect(list.amount_total).to eq 15.5
    expect(list.amount_paid).to eq 0
  end

  it '#call offloads to job when recipients exceed limit' do
    Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group))
    Subscription.create!(mailing_list: mailing_list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])

    list = InvoiceList.new(receiver: mailing_list, group: group, title: :title)

    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)
    invoice.invoice_items.build(name: 'pins', unit_cost: 0.5, count: 2)
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

  it '#call does not create any list model for recipient_ids' do
    list = InvoiceList.new(group: group)
    list.recipient_ids = [person.id, other_person.id].join(',')

    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)
    invoice.invoice_items.build(name: 'pins', unit_cost: 0.5, count: 2)
    list.invoice = invoice

    expect do
      Invoice::BatchCreate.call(list)
    end.to change { [group.invoices.count, group.invoice_items.count] }.by([2, 4])
    expect(list).not_to be_persisted
  end

  it '#call does not rollback if any save fails' do
    Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group))
    Subscription.create!(mailing_list: mailing_list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])

    list = InvoiceList.new(receiver: mailing_list, group: group, title: :title)
    invoice = Invoice.new(title: 'invoice', group: group)
    invoice.invoice_items.build(name: 'pens', unit_cost: 1.5)
    list.invoice = invoice

    allow_any_instance_of(Invoice).to receive(:save).and_wrap_original do |m|
      @saved = @saved ? false : m.call
    end

    expect do
      Invoice::BatchCreate.new(list).call
    end.to change { [group.invoices.count, group.invoice_items.count] }.by([1, 1])
    expect((list.invalid_recipient_ids)).to have(1).item
  end

  private

  def fabricate_donation(amount, received_at = 1.year.ago)
    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: other_person, recipient: person, group: group, state: :payed)
    Payment.create!(amount: amount, received_at: received_at, invoice: invoice)
  end
end
