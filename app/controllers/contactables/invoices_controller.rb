#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Contactables::InvoicesController < ListController
  include ExportableRedirect

  self.sort_mappings = {
    last_payment_at: Invoice.order_by_payment_statement,
    amount_paid: Invoice.order_by_amount_paid_statement
  }
  self.search_columns = [:title, :sequence_number]

  self.nesting = Group
  self.optional_nesting = Person

  skip_authorize_resource
  before_action :authorize_class
  before_action :entry, only: :show

  helper_method :filter_params, :entry, :received_invoice_path

  def show
    respond_to do |format|
      format.html
      format.pdf { render_pdf }
    end
  end

  private

  def entry
    @invoice ||= model_scope.find(params[:id]).decorate
  end

  def render_pdf
    Export::InvoicesJob.new(:pdf, exporting_person_id, [entry.id],
      {articles: true, payment_slip: true, reminders: true, filename: entry.filename(nil)}).enqueue!
    redirect_after_enqueued_export(received_invoice_path(entry))
  end

  def received_invoice_path(invoice, **options)
    if recipient.is_a?(Person)
      group_person_received_invoice_path(group, recipient, invoice, **options)
    else
      group_received_invoice_path(recipient, invoice, **options)
    end
  end

  def list_entries
    Invoice::Filter.new(params).apply(super.page(params[:page]).per(50))
  end

  def model_scope
    scope = super.received.preload(:group)
    return scope if all_received_invoices_visible?

    scope.issued_by_layers(current_ability.user_finance_layer_ids)
  end

  def all_received_invoices_visible?
    !FeatureGate.enabled?("invoices.filter_by_finance_layer") ||
      recipient_self_or_managed? ||
      recipient_in_finance_layer?
  end

  def recipient_self_or_managed?
    recipient == current_person || current_person.manageds.include?(recipient)
  end

  def recipient_in_finance_layer?
    recipient.is_a?(Group) &&
      current_ability.user_finance_layer_ids.include?(recipient.layer_group_id)
  end

  def recipient
    @recipient ||= parent
  end

  def group = parents.first

  def parent_scope = recipient.received_invoices.with_aggregated_payments

  def authorize_class
    authorize!(:index_received_invoices, recipient)
  end

  def filter_params
    year = Time.zone.today.year
    {from: params[:from] || "1.1.#{year}", to: params[:to] || "31.12.#{year}"}
  end
end
