# frozen_string_literal: true

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::Filter
  attr_reader :params

  def initialize(params = {})
    @params = params
  end

  def apply(scope)
    scope = apply_scope(scope, params[:state], Invoice::STATES)
    scope = apply_scope(scope, params[:due_since], Invoice::DUE_SINCE)
    scope = filter_by_ids(scope)
    scope = filter_by_invoice_run_id(scope)
    scope = scope.draft_or_issued(from: params[:from],
      to: params[:to])

    cancelled? ? scope : scope.visible
  end

  private

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

  def invoice_ids
    @invoice_ids = params[:ids].to_s.split(",")
  end
end
