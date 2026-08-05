# frozen_string_literal: true

#  Copyright (c) 2022-2026, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceRun do
  let(:list) { mailing_lists(:leaders) }
  let(:people_filter) { nil }
  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }

  describe "::scopes" do
    let(:template) do
      PeriodInvoiceTemplate.create!(
        name: "tmpl",
        group: group,
        recipient_source: GroupsFilter.create!(parent: group, group_type: group.class.name,
          active_at: Time.zone.today),
        start_on: 1.year.ago,
        end_on: Time.zone.today,
        items_attributes: [{
          name: "Mitgliedsbeitrag",
          type: PeriodInvoiceTemplate::RoleCountItem.name,
          dynamic_cost_parameters: {unit_cost: "5.00", role_types: [Group::TopGroup::Leader.name]}
        }]
      )
    end

    it ".standalone returns invoice_runs without a period_invoice_template" do
      subject.update!(group: group, title: :title, recipient_source: PeopleFilter.new)
      expect(InvoiceRun.standalone).to include subject
      expect(InvoiceRun.from_template).not_to include subject
    end

    it ".from_template returns invoice_runs with a period_invoice_template" do
      subject.update!(group: group, title: :title, recipient_source: template.recipient_source,
        period_invoice_template: template)
      expect(InvoiceRun.from_template).to include subject
      expect(InvoiceRun.standalone).not_to include subject
    end
  end

  describe "recipients" do
    let(:leader) { people(:top_leader) }
    let(:member) { people(:bottom_member) }

    it "reads people from recipients when mailing list" do
      subject.recipient_source = list
      list.subscriptions.first.update!(role_types: [Group::TopGroup::Leader])
      expect(list.people).to be_present
      expect(subject.recipients(person)).to eq [leader]
    end

    it "reads people from recipients when people filter" do
      subject.group = group
      subject.creator_id = leader.id
      subject.recipient_source = InvoiceRuns::RecipientSourceBuilder.new({ids: [member.id].join(",")},
        group).recipient_source
      expect(subject.recipients(leader)).to eq [member]
    end

    it "reads people from recipients when event participations filter" do
      subject.recipient_source = Event::ParticipationsFilter.new(event: events(:top_course))
      expect(subject.recipients(leader)).to eq [member]
    end

    it "returns none if recipient_source is nil" do
      subject.recipient_source = nil

      expect(subject.recipients(leader)).to eq []
    end

    it "returns none if recipient_source has been destroyed" do
      subject.recipient_source = list
      list.destroy!

      expect(subject.recipient_source_type).to eq "MailingList"
      expect(subject.recipient_source_id).to eq list.id
      expect(subject.recipients(leader)).to eq []
    end
  end

  describe "recipient_source" do
    it "accepts recipient_source as id and type" do
      Subscription.create!(mailing_list: list,
        subscriber: group,
        role_types: [Group::TopGroup::Leader])
      subject.attributes = {recipient_source_type: "MailingList", recipient_source_id: list.id}
      expect(subject.recipients(person).count).to eq 1
    end

    it "accepts mailing list as recipient_source" do
      subject.attributes = {title: :test, recipient_source: list}
      expect(subject).to be_valid
    end

    it "accepts people_filter as recipient_source" do
      subject.attributes = {title: :test, recipient_source: PeopleFilter.new}
      expect(subject).to be_valid
    end

    it "does not accept group as recipient_source" do
      subject.attributes = {title: :test, recipient_source: group}
      expect(subject).not_to be_valid
    end
  end

  it "#update_paid updates payment informations" do
    subject.update(group: group, title: :title, recipient_source: PeopleFilter.new)

    invoice = subject.invoices.create!(title: :title, recipient: person, total: 10, group: group)
    subject.invoices.create!(title: :title, recipient: other_person, total: 20, group: group)
    invoice.payments.create!(amount: 10)

    expect do
      subject.update_paid
    end.to change(subject, :amount_paid).from(0).to(10)
      .and change(subject, :recipients_paid).from(0).to(1)
  end

  it "#update_paid and #update_total update also invalid invoice_runs" do
    subject.update(group: group, title: :title, recipient_source: PeopleFilter.new)

    invoice = subject.invoices.create!(title: :title, recipient: person, total: 10, group: group)
    subject.invoices.create!(title: :title, recipient: other_person, total: 20, group: group)
    invoice.payments.create!(amount: 10)

    subject.title = ""
    subject.save(validate: false)
    subject.reload

    expect(subject).to be_invalid

    expect do
      subject.update_paid
      subject.update_total
      subject.reload
    end.to change(subject, :amount_paid).from(0).to(10)
      .and change(subject, :recipients_paid).from(0).to(1)
      .and change(subject, :recipients_total).from(0).to(2)
  end

  it "#to_s returns title" do
    subject.title = "A big invoice"
    expect(subject.to_s).to eq "A big invoice"
  end
end
