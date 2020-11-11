# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Invoice::BatchCreate
  attr_reader :invoice_list, :invoice

  def self.call(invoice_list, limit = 100)
    invoice_parameters = invoice_list.invoice_parameters
    if invoice_list.recipient_ids_count > limit
      invoice_list.save
      Invoice::BatchCreateJob.new(invoice_list.id, invoice_parameters).enqueue!
    else
      invoice_list.invoice = Invoice.new(invoice_parameters)
      Invoice::BatchCreate.new(invoice_list).call
    end
  end

  def initialize(invoice_list)
    @invoice_list = invoice_list
    @invoice = invoice_list.invoice
  end

  def call
    Invoice.transaction do
      invoice_list.save! if receiver? && invoice_list.new_record?
      create_invoices.tap do
        invoice_list.update_total if receiver?
      end
    end
  end

  private

  def receiver?
    invoice_list.receiver
  end

  def create_invoices
    results = []
    invoice_list.recipients.find_in_batches do |batch|
      results += batch.collect do |recipient|
        invoice_list.group.invoices.build(attributes(recipient)).save
      end
      invoice_list.update(recipients_processed: results.count(true)) if receiver?
    end
  end

  def attributes(recipient)
    invoice.attributes.merge(
      invoice_items_attributes: invoice.invoice_items.collect(&:attributes),
      recipient_id: recipient.id,
      invoice_list_id: invoice_list.id,
      creator_id: invoice_list.creator_id
    )
  end
end
