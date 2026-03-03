#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplates::InvoiceRunsController < InvoiceRunsController
  self.nesting = [Group, PeriodInvoiceTemplate]

  helper_method :group, :period_invoice_template

  def show
    redirect_to group_period_invoice_template_invoice_run_invoices_path(group,
      period_invoice_template, params[:id])
  end

  private

  def entry
    (model_ivar_get || model_ivar_set(params[:id] ? find_entry : build_entry)).tap do |entry|
      entry.group ||= group
    end
  end

  def find_entry
    group.invoice_runs.find(params[:id])
  end

  def assign_attributes
    super
    entry.group = group
    assign_invoice_items
  end

  def assign_invoice_items
    entry.invoice.invoice_items = period_invoice_template.items.map do |item|
      item.to_invoice_item(recipient_groups: period_invoice_template.recipient_source.entries)
    end
  end

  def group
    parents.first
  end

  def period_invoice_template
    parent
  end

  def recipient_source
    period_invoice_template.recipient_source
  end

  def return_path
    group_period_invoice_template_invoice_run_path(group_id: group.id,
      period_invoice_template_id: period_invoice_template.id, id: entry.id)
  end
end
