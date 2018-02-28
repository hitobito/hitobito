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

  def notice
    translate(updates)
  end

  def alert
    translate(errors)
  end

  def to_options
    present? ? { notice: notice, alert: alert } : { alert: empty_message }
  end

  private

  def present?
    [updates, errors].any?(&:present?)
  end

  def updates
    @updates ||= Hash.new { |h, k| h[k] = [] }
  end

  def errors
    @errors ||= Hash.new { |h, k| h[k] = [] }
  end

  def translate(hash)
    hash.collect { |key, invoices| line(key, invoices) }
  end

  def line(key, invoices)
    I18n.t("invoice_lists.update.#{key}",
           count: invoices.count,
           number: invoices.first.sequence_number)
  end

  def empty_message
    I18n.t('invoice_lists.update', count: 0)
  end

end
