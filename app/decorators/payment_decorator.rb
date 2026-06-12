# frozen_string_literal: true

#  Copyright (c) 2026-2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PaymentDecorator < ApplicationDecorator
  decorates :payment

  def amount = format_currency(model.amount)

  def received_at = model.received_at

  def status = model.status_label

  def invoice_amount = model.invoice.decorate.total

  def invoice_due_at = model.invoice.due_at

  def invoice_status = model.invoice.state_label

  def format_currency(amount)
    helpers.number_to_currency(amount, {unit: currency, format: "%n %u"})
  end

  def currency = model.invoice.decorate.currency
end
