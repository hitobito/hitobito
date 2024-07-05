# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id                 :bigint           not null, primary key
#  failed_count       :integer          default(0)
#  invoice_attributes :text(65535)
#  recipient_count    :integer          default(0)
#  salutation         :string(255)      default("none"), not null
#  sent_at            :datetime
#  state              :string(255)      default("draft")
#  subject            :string(256)
#  success_count      :integer          default(0)
#  text               :text(65535)
#  type               :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  invoice_list_id    :bigint
#  mailing_list_id    :bigint
#  sender_id          :bigint
#
# Indexes
#
#  index_messages_on_invoice_list_id  (invoice_list_id)
#  index_messages_on_mailing_list_id  (mailing_list_id)
#  index_messages_on_sender_id        (sender_id)
#
#  Copyright (c) 2012-2024, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Message::LetterWithInvoice do
  let(:invoice_attrs) {
    {
      "invoice_items_attributes" => {
        "1" => {"name" => "Mitgliedsbeitrag 2021", "_destroy" => "false"}
      }
    }
  }

  it "new record accepts invoice_attributes" do
    subject.mailing_list = mailing_lists(:leaders)
    subject.invoice_attributes = invoice_attrs
    expect(subject.invoice.invoice_items.first.name).to eq "Mitgliedsbeitrag 2021"
  end

  it "persisted record accepts updates to invoice_attributes" do
    message = messages(:with_invoice)
    message.update(invoice_attributes: invoice_attrs)
    expect(message.reload.invoice.invoice_items.first.name).to eq "Mitgliedsbeitrag 2021"
  end

  it "builds valid invoice_list" do
    message = messages(:with_invoice)
    expect(message.invoice_list).to be_valid
    message.save
    expect(message.invoice_list).to be_persisted
  end

  describe "reading recipients and invoices" do
    let(:recipient) { people(:bottom_member) }
    let(:group) { groups(:top_layer) }

    subject { messages(:with_invoice) }

    context "without invoice list" do
      it "#invoice_for builds valid invoice" do
        invoice = subject.invoice_for(recipient)
        expect(invoice).to be_valid
        expect(invoice).to be_new_record
        expect(invoice.recipient_address).to be_present
      end

      it "#recipients uses recipients from mailing_list" do
        Fabricate(:subscription, subscriber: recipient, mailing_list: subject.mailing_list)
        expect(subject.recipients).to have(1).items
      end
    end

    context "with invoice list" do
      before do
        list = InvoiceList.create(group: group, title: "title")
        list.invoices.create!(title: :title, recipient_id: recipient.id, total: 10, group: group)
        subject.invoice_list_id = list.id
      end

      it "#invoice_for loads persisted invoice" do
        invoice = subject.invoice_for(recipient)
        expect(invoice).to be_persisted
        expect(invoice.recipient_address).to be_present
      end

      it "#recipients uses invoice recipients" do
        expect(subject.recipients).to have(1).item
      end

      it "#recipients only considers Person.with_address" do
        recipient.update(street: nil)
        expect(subject.recipients).to be_empty
      end
    end
  end

  context "invoice items" do
    let(:letter) { messages(:with_invoice) }
    let(:invalid_invoice_item_attrs) { {"name" => "Invalid Item", "count" => nil, "unit_cost" => nil} }

    it "validates invoice items" do
      letter.invoice_attributes["invoice_items_attributes"][2] = invalid_invoice_item_attrs
      expect(letter).not_to be_valid
    end
  end
end
