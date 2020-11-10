# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Invoice::BatchCreate
  attr_reader :invoice_list, :invoice

  def initialize(invoice_list)
    @invoice_list = invoice_list
    @invoice = invoice_list.invoice
  end

  def call
    Invoice.transaction do
      invoice_list.save! if receiver?
      create_invoices
      update_total if receiver?
    end
  end

  private

  def receiver?
    invoice_list.receiver
  end

  def create_invoices
    invoice_list.recipients.all? do |recipient|
      invoice_list.group.invoices.build(attributes(recipient)).save
    end || (raise ActiveRecord::Rollback)
  end

  def attributes(recipient)
    invoice.attributes.merge(
      invoice_items_attributes: invoice.invoice_items.collect(&:attributes),
      recipient_id: recipient.id,
      invoice_list_id: invoice_list.id,
      creator_id: invoice_list.creator_id
    )
  end

  def update_total
    total_sum = invoice_list.invoices.sum(&:total)
    total_count = invoice_list.invoices.pluck(:recipient_id).count
    invoice_list.update(amount_total: total_sum, recipients_total: total_count)
  end
end
