#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Create actual invoices for a given invoice-list.
#
# The main worker method is #create_invoices.
# The Invoice-List ist updated with success/failure counts
# Failures are invoices without invoice-items or any other more specific validation error.
class Invoice::BatchCreate
  attr_reader :invoice_run, :invoice, :results, :invalid

  def self.call(invoice_run, limit = InvoiceRunsController::LIMIT_CREATE)
    if invoice_run.recipient_ids_count < limit
      create(invoice_run)
    else
      create_async(invoice_run)
    end
  end

  def self.create(invoice_run)
    Invoice::BatchCreate.new(invoice_run).call
  end

  def self.create_async(invoice_run)
    Invoice::BatchCreateJob.new(invoice_run.id, invoice_run.invoice_parameters).enqueue!
  end

  def initialize(invoice_run, people = nil)
    @invoice_run = invoice_run
    @invoice = invoice_run.invoice
    @people = people # used by Messages::LetterWithInvoiceDispatch#batch_create
    @results = []
    @invalid = []
  end

  def call
    create_invoices
    invoice_run.update_total
  end

  private

  def create_invoices
    receivers.each_slice(1000) do |slice|
      slice.each do |receiver|
        success = create_invoice(receiver)
        invalid << receiver.id unless success
        results << success
      end

      update_invoice_run
    end
  end

  def create_invoice(recipient) # rubocop:todo Metrics/AbcSize
    invoice_attrs = invoice.attributes.merge(
      title: invoice_run.fixed_fee ? title_with_layer(recipient.layer_group_id) : invoice.title,
      creator_id: invoice_run.creator_id,
      invoice_run_id: invoice_run.id,
      recipient_id: recipient.id,
      recipient_type: recipient.type
    )
    invoice = invoice_run.group.issued_invoices.build(invoice_attrs)

    add_invoice_items(invoice, recipient)
    invoice.save if invoice.invoice_items.any?
  end

  def add_invoice_items(invoice, recipient)
    if invoice_run.fixed_fee
      invoice.invoice_items = InvoiceRuns::FixedFee.for(invoice_run.fixed_fee,
        recipient.layer_group_id).invoice_items
    else
      invoice.invoice_items_attributes = invoice_items_attributes(recipient.id)
    end
  end

  def update_invoice_run
    invoice_run.update(recipients_processed: results.count(true), invalid_recipient_ids: invalid)
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
    return invoice_run.receivers if invoice_run.receivers.present?

    invoice_run.recipients.find_each.lazy.map do |person|
      InvoiceRuns::Receiver.new(id: person.id, type: person.class.sti_name)
    end
  end

  def group_id
    invoice_run.group.layer_group.id
  end
end
