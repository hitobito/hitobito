#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PaymentsController < CrudController
  include FormatHelper
  include ActionView::Helpers::NumberHelper
  include ExportableRedirect

  self.nesting = [Group]
  self.optional_nesting = [Invoice]
  self.permitted_attrs = [:amount, :received_at]

  self.sort_mappings = {
    invoice_amount: "invoices.total",
    invoice_due_at: "invoices.due_at",
    invoice_status: "invoices.state",
    amount: "payments.amount",
    received_at: "payments.received_at",
    status: "payments.status"
  }

  self.remember_params += %w[invoice_status status]

  self.search_columns = [
    "invoices.reference",
    "invoices.sequence_number",
    "invoices.title",
    "people.first_name",
    "people.last_name",
    "people.email",
    "groups.name",
    "groups.short_name",
    "groups.email"
  ]

  helper_method :filter_params

  def index
    respond_to do |format|
      format.csv { render_tabular_entries_in_background(:csv) }
      format.xlsx { render_tabular_entries_in_background(:xlsx) }
      format.html { super }
    end
  end

  def create
    assign_attributes

    Payment.transaction do
      invoice = parents.last
      if entry.save
        invoice.invoice_run&.update_paid
        redirect_to(invoice.decorate.show_path, notice: flash_message)
      else
        flash[:payment] = permitted_params.to_h
        redirect_to(group_invoice_path(*parents))
      end
    end
  end

  private

  def render_tabular_entries_in_background(format)
    return_path = group_invoices_path(params[:group_id])
    render_tabular_in_background(format, :payment_export)
    redirect_after_enqueued_export(return_path)
  end

  def render_tabular_in_background(format, filename)
    Export::PaymentsExportJob.new(
      format, current_person.id, entries.map(&:id),
      {filename: filename}
    ).enqueue!
  end

  def flash_message
    I18n.t("#{controller_name}.#{action_name}.flash.success", amount: f(entry.amount))
  end

  def assign_attributes
    super
    entry.status = :manually_created
  end

  def list_entries
    scope = super
    scope = scope.joins(<<~SQL)
      LEFT JOIN invoices ON payments.invoice_id = invoices.id
      LEFT JOIN people ON people.id = invoices.recipient_id AND invoices.recipient_type = 'Person'
      LEFT JOIN groups ON groups.id = invoices.recipient_id AND invoices.recipient_type = 'Group'
    SQL

    scope = scope.unassigned if params[:state] == "without_invoice"
    scope = scope.page(params[:page]) if params[:ids].blank?
    scope.where(received_at: from_param..to_param)
  end

  def from_param
    @from_param ||= extract_date_param(:from) || Time.zone.today.beginning_of_year
  end

  def to_param
    @to_param ||= extract_date_param(:to) || Time.zone.today.end_of_year
  end

  def extract_date_param(param)
    Date.parse(params[param])
  rescue TypeError, Date::Error
    nil
  end

  def model_scope
    if action_name == "index"
      if parents.one? # only a group present
        Payment.of_layer(parent).includes(:invoice)
      else # group and invoice, crashes rightfully if neither is present
        @invoice.payments # ivar is loaded by the parents-call above
      end
    else
      super
    end
  end

  def filter_params
    year = Time.zone.today.year
    {from: params[:from] || "1.1.#{year}", to: params[:to] || "31.12.#{year}"}
  end
end
