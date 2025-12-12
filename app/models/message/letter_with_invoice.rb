# frozen_string_literal: true

#  Copyright (c) 2012-2022, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class Message::LetterWithInvoice < Message::Letter
  belongs_to :invoice_run
  serialize :invoice_attributes, type: Hash, coder: YAML
  validate :assert_valid_invoice_items

  self.icon = :"file-invoice"

  def invoice_run
    @invoice_run ||= InvoiceRun.create!(
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
      invoice_attributes.to_h.fetch("invoice_items_attributes", {}).values.each do |v|
        invoice.invoice_items.build(v.except("_destroy"))
      end
    end
  end

  def invoice_for(receiver)
    invoice_run_id ? load_invoice_for(receiver) : build_invoice_for(receiver)
  end

  def recipients
    recipients = invoice_run_id ? recipients_from_invoices : recipients_from_mailing_list
    recipients.merge(Person.with_address)
  end

  private

  def recipients_from_invoices
    invoices = Invoice.joins(:invoice_run).where(invoice_run_id: invoice_run_id)
    Person.where(id: invoices.select("recipient_id"))
  end

  def recipients_from_mailing_list
    mailing_list.people
  end

  def load_invoice_for(receiver)
    Invoice.find_by(invoice_run_id: invoice_run_id, recipient: receiver).tap do |invoice|
      raise "Didn't find invoice for recipient " + receiver.inspect unless invoice
    end
  end

  def build_invoice_for(receiver)
    invoice.tap do |invoice|
      invoice.recipient = receiver
      invoice.send(:set_recipient_fields!)
      raise "invoice invalid" unless invoice.valid?
    end
  end

  def assert_valid_invoice_items
    if invoice.invoice_items.empty?
      errors.add(:base, :invoice_items_required)
    elsif !invoice.invoice_items.all?(&:valid?)
      errors.add(:base, :invoice_items_invalid)
    end
  end
end
