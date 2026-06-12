# frozen_string_literal: true

#  Copyright (c) 2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# - [ ] `Payment::Filter` erstellen analog `Invoice::Filter`:
#   - Filter für `status` (Payment::STATES)
#   - Filter für `invoice_state` (Invoice::STATES)
#   - Filter für `ids` (für selektierte Zeilen beim Export)
#   - Filter für `received_at` (from/to)
#   - Behalte bestehenden `unassigned` Filter für CSV Export Kompatibilität (`params[:status] == "without_invoice"`)
class Payments::Filter
  def initialize(params = {})
    @params = params
  end

  def apply(scope)
    return scope if no_params_set?

    scope = apply_scope(scope, @params[:status], Payment::STATES - ["without_invoice"])
    scope = scope.unassigned if @params[:status] == "without_invoice"

    scope = scope.where(received_at: from_param..to_param)

    scope = apply_invoice_scope(scope, @params[:invoice_status], Invoice::STATES)

    filter_by_ids(scope)
  end

  private

  def no_params_set?
    possible_keys = %w[status invoice_status ids from to]

    (@params.keys.map(&:to_s) & possible_keys).none?
  end

  def from_param
    @from_param ||= extract_date_param(:from) || Time.zone.today.beginning_of_year
  end

  def to_param
    @to_param ||= extract_date_param(:to) || Time.zone.today.end_of_year
  end

  def extract_date_param(param)
    Date.parse(@params[param].to_s)
  rescue TypeError, Date::Error
    nil
  end

  def apply_scope(relation, scope, valid_scopes)
    return relation unless valid_scopes.include?(scope)

    relation.send(scope)
  end

  def apply_invoice_scope(relation, scope, valid_scopes)
    return relation unless valid_scopes.include?(scope)

    relation.left_joins(:invoice).merge(Invoice.send(scope))
  end

  def filter_by_ids(relation)
    return relation if @params[:ids].blank? || all_payments?

    relation.where(id: payment_ids)
  end

  def all_payments?
    @params[:ids] == "all"
  end

  def payment_ids
    @payment_ids = @params[:ids].to_s.split(",")
  end
end
