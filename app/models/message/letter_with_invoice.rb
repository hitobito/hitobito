# == Schema Information
#
# Table name: messages
#
#  id              :bigint           not null, primary key
#  failed_count    :integer          default(0)
#  recipient_count :integer          default(0)
#  sent_at         :datetime
#  state           :string(255)      default("draft")
#  subject         :string(1024)     not null
#  success_count   :integer          default(0)
#  type            :string(255)      not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  mailing_list_id :bigint
#  sender_id       :bigint
#  invoice_list_id :bigint
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

  self.icon = :'file-invoice'

  def invoice_list
    @invoice_list ||= InvoiceList.create!(
      title: subject,
      group: group,
      receiver: mailing_list,
      invoice: invoice
    )
  end

  def invoice
    @invoice ||= Invoice.new.tap do |invoice|
      invoice.group = group
      invoice.group = group.layer_group
      invoice.title = subject
      invoice_attributes.to_h.fetch("invoice_items_attributes", {}).values.each do |v|
        invoice.invoice_items.build(v.except("_destroy"))
      end
    end
  end

  def invoice_for(receiver)
    invoice.tap do |invoice|
      invoice.recipient = receiver
      invoice.send(:set_recipient_fields)
      raise "invoice invalid" unless invoice.valid?
    end
  end
end
