# frozen_string_literal: true

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::Filter
  attr_reader :params

  TYPE_SCOPES = Invoice::TYPE_SCOPES

  def initialize(params = {})
    @params = params
  end

  def apply(scope)
    return scope if no_params_set?

    scope = apply_scope(scope, params[:state], Invoice::STATES)
    scope = apply_scope(scope, params[:due_since], Invoice::DUE_SINCE)
    scope = filter_by_ids(scope)
    scope = filter_by_invoice_run_id(scope)
    scope = filter_by_invoice_type(scope)
    scope = filter_by_daterange(scope)

    cancelled? ? scope : scope.visible
  end

  def apply_or_none(scope)
    if no_params_set?
      scope.none
    else
      apply(scope)
    end
  end

  private

  def no_params_set?
    possible_keys = %w[state due_since ids invoice_run_id from to] +
      Invoice::TYPE_SCOPES.map(&:to_s)

    (params.keys.map(&:to_s) & possible_keys).none?
  end

  def apply_scope(relation, scope, valid_scopes)
    return relation unless valid_scopes.include?(scope)

    relation.send(scope)
  end

  def cancelled?
    params[:state] == "cancelled"
  end

  def filter_by_invoice_run_id(relation)
    return relation if params[:invoice_run_id].blank?

    relation.where(invoice_run_id: params[:invoice_run_id])
  end

  def filter_by_ids(relation)
    return relation if params[:ids].blank? || all_invoices?

    relation.where(id: invoice_ids)
  end

  def filter_by_daterange(relation)
    return relation if params[:singular]

    relation.draft_or_issued(from: params[:from], to: params[:to])
  end

  def filter_by_invoice_type(relation)
    return relation unless invoice_type_params_present?

    scopes = TYPE_SCOPES
      .select { |type| type_param_set_or_missing(type) }
      .map { |type| Invoice.send(type) }

    return relation.none if scopes.empty?
    return relation if scopes.size == TYPE_SCOPES.size

    relation.where(id: scopes.reduce(:or).select(:id))
  end

  def invoice_type_params_present?
    (params.keys.map(&:to_s) & TYPE_SCOPES.map(&:to_s)).any?
  end

  def all_invoices?
    params[:ids] == "all"
  end

  def type_param_set_or_missing(type)
    ActiveModel::Type::Boolean.new.cast(params[type]) || !params.key?(type)
  end

  def invoice_ids
    @invoice_ids = params[:ids].to_s.split(",")
  end

  def boolean_param_value(key)
  end
end
