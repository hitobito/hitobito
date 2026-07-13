#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Contactables::InvoicesController < ListController
  self.sort_mappings = {
    last_payment_at: Invoice.order_by_payment_statement,
    amount_paid: Invoice.order_by_amount_paid_statement,
    recipient: "people.order_name ASC"
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
    scope = filter_by_finance_layer? ? filter_by_finance_layer(super) : super

    scope.preload(:group)
  end

  def filter_by_finance_layer?
    FeatureGate.enabled?("invoices.filter_by_finance_layer") &&
      !self_or_managed?
  end

  def self_or_managed?
    contactable == current_person || current_person.manageds.include?(contactable)
  end

  def filter_by_finance_layer(scope)
    scope
      .joins(group: :layer_group)
      .where(layer_group: {id: current_ability.user_finance_layer_ids})
  end

  def contactable
    @contactable ||= parent
  end

  def recipient_table_name = contactable.class.table_name

  def recipient_type = contactable.class.sti_name

  def parent_scope = parent.received_invoices.with_aggregated_payments

  def authorize_class
    authorize!(:index_received_invoices, contactable)
  end

  def filter_params
    year = Time.zone.today.year
    {from: params[:from] || "1.1.#{year}", to: params[:to] || "31.12.#{year}"}
  end
end
