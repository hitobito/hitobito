#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require "spec_helper"

describe Invoice::BatchCreate do
  include ActiveJob::TestHelper

  let(:mailing_list) { mailing_lists(:leaders) }
  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }

  it "#call creates invoices for abo" do
    Subscription.create!(mailing_list: mailing_list,
      subscriber: group,
      role_types: [Group::TopGroup::Leader])

    run = InvoiceRun.create!(receiver: mailing_list, group: group, title: :title)

    invoice = Fabricate.build(:invoice, title: "invoice", group: group)
    invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
    invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
    run.invoice = invoice
    expect do
      Invoice::BatchCreate.call(run)
    end.to change { group.issued_invoices.count }.by(1)
      .and change { group.invoice_items.count }.by(2)
    expect(run.reload).to have(1).invoices
    expect(run.receiver).to eq mailing_list
    expect(run.recipients_total).to eq 1
    expect(run.recipients_paid).to eq 0
    expect(run.amount_total).to eq 2.5
    expect(run.amount_paid).to eq 0
  end

  it "#call creates invoices for group distinct people regardless of role count" do
    group = groups(:bottom_layer_one)
    group.issued_invoices.destroy_all

    # rubocop:todo Layout/LineLength
    Fabricate(Group::BottomLayer::Leader.sti_name.to_sym, person: other_person, group: group) # second role for other_person
    # rubocop:enable Layout/LineLength
    2.times do
      Fabricate(Group::BottomLayer::Member.sti_name.to_sym, group: group)
    end
    expect(group.roles.size).to eq(4)
    expect(group.people.size).to eq(4) # people relation goes via roles and are currently not distinct

    run = InvoiceRun.create!(receiver: group, group: group, title: :title)

    invoice = Fabricate.build(:invoice, title: "invoice", group: group)
    invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
    invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
    run.invoice = invoice

    expect do
      Invoice::BatchCreate.call(run)
    end.to change { group.issued_invoices.count }.by(3)
      .and change { group.invoice_items.count }.by(6)
    expect(run.reload).to have(3).invoices
    expect(run.receiver).to eq group
    expect(run.recipients_total).to eq 3
    expect(run.recipients_paid).to eq 0
    expect(run.amount_total).to eq 7.5
    expect(run.amount_paid).to eq 0
  end

  it "#call offloads to job when recipients exceed limit" do
    Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group))
    Subscription.create!(mailing_list: mailing_list,
      subscriber: group,
      role_types: [Group::TopGroup::Leader])

    run = InvoiceRun.create!(receiver: mailing_list, group: group, title: :title)

    invoice = Fabricate.build(:invoice, title: "invoice", group: group)
    invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
    invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
    run.invoice = invoice

    expect do
      Invoice::BatchCreate.call(run, 1)
      Delayed::Job.last.payload_object.perform
    end.to change { group.issued_invoices.count }.by(2)
      .and change { group.invoice_items.count }.by(4)
    expect(run.reload).to have(2).invoices
    expect(run.receiver).to eq mailing_list
    expect(run.recipients_total).to eq 2
    expect(run.recipients_paid).to eq 0
    expect(run.amount_total).to eq 5
    expect(run.amount_paid).to eq 0
    expect(run.recipients_processed).to eq 2
  end

  it "#call does not create any run model for recipient_ids" do
    run = InvoiceRun.new(group: group)
    run.recipient_ids = [person.id, other_person.id].join(",")

    invoice = Fabricate.build(:invoice, title: "invoice", group: group)
    invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
    invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
    run.invoice = invoice

    expect do
      Invoice::BatchCreate.call(run)
    end.to change { group.issued_invoices.count }.by(2)
      .and change { group.invoice_items.count }.by(4)
    expect(run).not_to be_persisted
  end

  it "#call does not rollback if any save fails" do
    Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group))
    Subscription.create!(mailing_list: mailing_list,
      subscriber: group,
      role_types: [Group::TopGroup::Leader])

    run = InvoiceRun.new(receiver: mailing_list, group: group, title: :title)
    invoice = Fabricate.build(:invoice, title: "invoice", group: group)
    invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
    run.invoice = invoice

    allow_any_instance_of(Invoice).to receive(:save).and_wrap_original do |m|
      @saved = @saved ? false : m.call
    end

    expect do
      Invoice::BatchCreate.new(run).call
    end.to change { group.issued_invoices.count }.by(1)
      .and change { group.invoice_items.count }.by(1)
    expect(run.invalid_recipient_ids).to have(1).item
  end

  private

  def fabricate_donation(amount, received_at = 1.year.ago)
    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: other_person, recipient: person, group: group,
      state: :payed)
    Payment.create!(amount: amount, received_at: received_at, invoice: invoice)
  end
end
