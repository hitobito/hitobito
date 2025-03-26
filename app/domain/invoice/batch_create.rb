#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::BatchCreate
  attr_reader :invoice_list, :invoice, :results, :invalid

  def self.call(invoice_list, limit = InvoiceListsController::LIMIT_CREATE)
    invoice_parameters = invoice_list.invoice_parameters
    if invoice_list.recipient_ids_count < limit
      create(invoice_list, invoice_parameters)
    else
      create_async(invoice_list, invoice_parameters)
    end
  end

  def self.create(invoice_list, invoice_parameters)
    invoice_list.invoice = Invoice.new(invoice_parameters)
    Invoice::BatchCreate.new(invoice_list).call
  end

  def self.create_async(invoice_list, invoice_parameters)
    invoice_list.save
    Invoice::BatchCreateJob.new(invoice_list.id, invoice_parameters).enqueue!
  end

  def initialize(invoice_list, people = nil)
    @invoice_list = invoice_list
    @invoice = invoice_list.invoice
    @people = people
    @results = []
    @invalid = []
  end

  def call
    if receiver? && invoice_list.new_record?
      invoice_list.recipients_total = invoice_list.recipient_ids_count
      invoice_list.save!
    end
    create_invoices.tap do
      invoice_list.update_total if receiver?
    end
  end

  def create_invoice(recipient)
    attrs = attributes(recipient)
    invoice_list.group.invoices.build(attrs).save
  end

  private

  def receiver?
    invoice_list.receiver
  end

  def create_invoices
    recipients.find_in_batches do |batch|
      batch.each do |recipient|
        success = create_invoice(recipient)
        invalid << recipient.id unless success
        results << success
      end
      update_invoice_list if receiver?
    end
  end

  def recipients
    @people || invoice_list.recipients
  end

  def update_invoice_list
    invoice_list.update(recipients_processed: results.count(true), invalid_recipient_ids: invalid)
  end

  def attributes(recipient)
    invoice.attributes.merge(
      invoice_items_attributes: invoice_items_attributes(recipient),
      recipient_id: recipient.id,
      invoice_list_id: invoice_list.id,
      creator_id: invoice_list.creator_id
    )
  end

  def invoice_items_attributes(recipient)
    invoice.invoice_items.collect do |item|
      attrs = item.attributes
      if item.dynamic
        item.dynamic_cost_parameters[:recipient_id] = recipient.id
        item.dynamic_cost_parameters[:group_id] = group_id
        attrs[:cost] = item.dynamic_cost
      end
      # Do not try to save invalid item since that would abort the whole invoice create transaction
      attrs if InvoiceItem.new(attrs).recalculate.valid?
    end.compact
  end

  def group_id
    invoice_list.group.layer_group.id
  end
end
