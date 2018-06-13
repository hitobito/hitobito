# encoding: utf-8

#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
class Invoice::BatchUpdateResult

  def track_update(key, invoice)
    updates[key.to_sym] << invoice
  end

  def track_error(key, invoice)
    errors[key.to_sym] << invoice
  end

  def track_model_error(invoice)
    model_errors << model_error_message(invoice)
  end

  def notice
    translate(updates)
  end

  def alert
    model_errors + translate(errors)
  end

  def to_options
    present? ? { notice: notice, alert: alert } : { alert: empty_message }
  end

  def present?
    [updates, errors, model_errors].any?(&:present?)
  end

  private

  def updates
    @updates ||= Hash.new { |h, k| h[k] = [] }
  end

  def errors
    @errors ||= Hash.new { |h, k| h[k] = [] }
  end

  def model_errors
    @model_errors ||= []
  end

  def translate(hash)
    hash.collect { |key, invoices| message(key, invoices) }
  end

  def model_error_message(invoice)
    I18n.t('invoice_lists.update.model_error',
           number: invoice.sequence_number,
           error: invoice.errors.full_messages.join(', '))
  end

  def message(key, invoices)
    I18n.t("invoice_lists.update.#{key}",
           count: invoices.count,
           number: invoices.first.sequence_number)
  end

  def empty_message
    I18n.t('invoice_lists.update', count: 0)
  end

end
