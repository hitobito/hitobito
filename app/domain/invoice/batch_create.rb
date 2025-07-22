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
    Invoice::BatchCreate.new(invoice_list).call
  end

  def self.create_async(invoice_list, invoice_parameters)
    Invoice::BatchCreateJob.new(invoice_list.id, invoice_parameters).enqueue!
  end

  def initialize(invoice_list, people = nil)
    @invoice_list = invoice_list
    @invoice = invoice_list.invoice
    @people = people # used by Messages::LetterWithInvoiceDispatch#batch_create
    @results = []
    @invalid = []
  end

  def call
    create_invoices
    invoice_list.update_total
  end

  private

  def create_invoices
    receivers.each do |receiver|
      success = create_invoice(receiver)
      invalid << receiver.id unless success
      results << success
      update_invoice_list
    end
  end

  def create_invoice(recipient)
    invoice_attrs = invoice.attributes.merge(
      title: invoice_list.fixed_fee ? title_with_layer(recipient.layer_group_id) : invoice.title,
      creator_id: invoice_list.creator_id,
      invoice_list_id: invoice_list.id,
      recipient_id: recipient.id
    )
    invoice = invoice_list.group.invoices.build(invoice_attrs)

    add_invoice_items(invoice, recipient)
    invoice.save if invoice.invoice_items.any?
  end

  def add_invoice_items(invoice, recipient)
    if invoice_list.fixed_fee
      invoice.invoice_items = InvoiceLists::FixedFee.for(invoice_list.fixed_fee, recipient.layer_group_id).invoice_items
    else
      invoice.invoice_items_attributes = invoice_items_attributes(recipient.id)
    end
  end

  def update_invoice_list
    invoice_list.update(recipients_processed: results.count(true), invalid_recipient_ids: invalid)
  end

  def invoice_items_attributes(recipient_id)
    invoice.invoice_items.collect do |item|
      attrs = item.attributes
      if item.dynamic
        item.dynamic_cost_parameters[:recipient_id] = recipient_id
        item.dynamic_cost_parameters[:group_id] = group_id
        attrs[:cost] = item.dynamic_cost
      end
      # Do not try to save invalid item since that would abort the whole invoice create transaction
      attrs if InvoiceItem.new(attrs).recalculate.valid?
    end.compact
  end

  def title_with_layer(layer_group_id)
    return invoice.title unless layer_group_id

    [invoice.title, Group.find(layer_group_id).name].join(" - ")
  end

  def receivers
    return invoice_list.receivers if invoice_list.receivers.present?

    invoice_list.recipients.find_each.lazy.map do |person|
      InvoiceLists::Receiver.new(id: person.id)
    end
  end

  def group_id
    invoice_list.group.layer_group.id
  end
end
