# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require "spec_helper"

describe InvoiceList do
  let(:list)         { mailing_lists(:leaders) }
  let(:group)        { groups(:top_layer) }
  let(:person)       { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }

  it "accepts recipient_ids as comma-separates values" do
    subject.attributes = { recipient_ids: "#{person.id},#{other_person.id}" }
    expect(subject.recipient_ids_count).to eq 2
    expect(subject.first_recipient).to eq person
  end

  it "accepts receiver as id and type" do
    Subscription.create!(mailing_list: list,
                         subscriber: group,
                         role_types: [Group::TopGroup::Leader])
    subject.attributes = { receiver_type: "MailingList", receiver_id: list.id }
    expect(subject.recipient_ids_count).to eq 1
    expect(subject.first_recipient).to eq person
  end

  it "only accepts mailing list as receiver" do
    subject.attributes = { title: :test, receiver: list }
    expect(subject).to be_valid

    subject.attributes = { title: :test, receiver: group }
    expect(subject).not_to be_valid
  end

  it "#update_paid updates payment informations" do
    subject.update(group: group, title: :title)
    invoice = subject.invoices.create!(title: :title, recipient_id: person.id, total: 10, group: group)
    subject.invoices.create!(title: :title, recipient_id: other_person.id, total: 20, group: group)
    invoice.payments.create!(amount: 10)
    subject.update_paid
    expect(subject.amount_paid).to eq 10
    expect(subject.recipients_paid).to eq 1
  end
end
