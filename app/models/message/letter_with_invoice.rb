# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id                 :bigint           not null, primary key
#  failed_count       :integer          default(0)
#  invoice_attributes :text(65535)
#  recipient_count    :integer          default(0)
#  salutation         :string(255)
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

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Message::LetterWithInvoice < Message::Letter

  belongs_to :invoice_list
  serialize :invoice_attributes, Hash
  validate :assert_valid_invoice_items

  self.icon = :'file-invoice'

  def invoice_list
    @invoice_list ||= InvoiceList.create!(
      title: subject,
      group: group.layer_group,
      receiver: mailing_list,
      invoice: invoice
    )
  end

  def invoice
    @invoice ||= Invoice.new.tap do |invoice|
      invoice.group = group.layer_group
      invoice.title = subject
      invoice_attributes.to_h.fetch('invoice_items_attributes', {}).values.each do |v|
        invoice.invoice_items.build(v.except('_destroy'))
      end
    end
  end

  def invoice_for(receiver)
    invoice_list_id ? load_invoice_for(receiver) : build_invoice_for(receiver)
  end

  def recipients
    recipients = invoice_list_id ? recipients_from_invoices : recipients_from_mailing_list
    recipients.merge(Person.with_address)
  end

  private

  def recipients_from_invoices
    invoices = Invoice.joins(:invoice_list).where(invoice_list_id: invoice_list_id)
    Person.where(id: invoices.select("recipient_id"))
  end

  def recipients_from_mailing_list
    mailing_list.people
  end

  def load_invoice_for(receiver)
    Invoice.find_by(invoice_list_id: invoice_list_id, recipient: receiver).tap do |invoice|
      raise 'Didn\'t find invoice for recipient ' + receiver.inspect unless invoice
    end
  end

  def build_invoice_for(receiver)
    invoice.tap do |invoice|
      invoice.recipient = receiver
      invoice.send(:set_recipient_fields)
      raise 'invoice invalid' unless invoice.valid?
    end
  end

  def assert_valid_invoice_items
    unless invoice.invoice_items.all?(&:valid?)
      errors.add(:base, :invoice_items_invalid)
    end
  end

end
