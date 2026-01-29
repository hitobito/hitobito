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
  attr_reader :invoice_run, :current_user, :invoice, :results, :invalid

  def self.call(invoice_run, current_user, limit = InvoiceRunsController::LIMIT_CREATE)
    if invoice_run.recipients(current_user).count < limit
      create(invoice_run, current_user)
    else
      create_async(invoice_run, current_user)
    end
  end

  def self.create(invoice_run, current_user)
    Invoice::BatchCreate.new(invoice_run, current_user).call
  end

  def self.create_async(invoice_run, current_user)
    Invoice::BatchCreateJob.new(invoice_run.id, current_user.id,
      invoice_run.invoice_parameters).enqueue!
  end

  def initialize(invoice_run, current_user, people = nil)
    @invoice_run = invoice_run
    @current_user = current_user
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
    invoice_run.recipients(current_user).each_slice(1000) do |slice|
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
      title: invoice_run.fixed_fee ? title_with_layer(recipient) : invoice.title,
      creator_id: invoice_run.creator_id,
      invoice_run_id: invoice_run.id,
      recipient: recipient
    )
    invoice = invoice_run.group.issued_invoices.build(invoice_attrs)

    add_invoice_items(invoice, recipient)
    invoice.save if invoice.invoice_items.any?
  end

  def add_invoice_items(invoice, recipient)
    if invoice_run.fixed_fee
      invoice.invoice_items = InvoiceRuns::FixedFee.for(invoice_run.fixed_fee,
        recipient.layer_group.id).invoice_items
      invoice.invoice_items.each do |item|
        item.invoice = invoice
        item.recalculate
      end
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

  def title_with_layer(recipient)
    return invoice.title unless recipient

    [invoice.title, recipient.layer_group.name].join(" - ")
  end

  def group_id
    invoice_run.group.layer_group.id
  end
end
