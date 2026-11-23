#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Contactables::InvoicesController < ListController
  self.sort_mappings = {
    last_payment_at: Invoice.order_by_payment_statement,
    amount_paid: Invoice.order_by_amount_paid_statement
  }
  self.search_columns = [:title, :sequence_number]

  self.nesting = Group
  self.optional_nesting = Person

  helper_method :filter_params

  private

  def list_entries
    Invoice::Filter.new(params).apply(super.page(params[:page]).per(50))
  end

  def model_scope
    scope = super.preload(:group)
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

  def parent_scope = recipient.received_invoices.with_aggregated_payments

  def authorize_class
    authorize!(:index_received_invoices, recipient)
  end

  def filter_params
    year = Time.zone.today.year
    {from: params[:from] || "1.1.#{year}", to: params[:to] || "31.12.#{year}"}
  end
end
