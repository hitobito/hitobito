# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::History
  attr_reader :template, :invoice

  delegate :content_tag, :l, :t, :concat, :number_to_currency, to: :template

  def initialize(template, invoice)
    @template = template
    @invoice = invoice
  end

  def to_s
    content_tag :table do
      table_rows = [
        invoice_history_entry(invoice_issued_data, 'blue'),
        invoice_history_entry(invoice_sent_data, 'blue')
      ]

      table_rows << invoice_reminder_rows
      table_rows << invoice_payment_rows
      table_rows.compact.join.html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  private

  def invoice_reminder_rows
    if invoice.reminder_sent?
      invoice.payment_reminders.collect.with_index do |reminder, count|
        next unless reminder.persisted?
        invoice_history_entry(reminder_sent_data(reminder, count + 1), 'red')
      end
    end
  end

  def invoice_payment_rows
    if invoice.payments.present?
      invoice.payments.collect do |payment|
        next unless payment.persisted?
        invoice_history_entry(payment_data(payment), 'green')
      end
    end
  end

  def invoice_history_entry(data, color)
    return unless data
    content_tag :tr do
      data.collect do |d|
        concat content_tag(:td, d, class: color)
      end.to_s.html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  def invoice_issued_data
    if invoice.issued_at?
      [
        '⬤', # Middle Dot
        l(invoice.issued_at, format: :long),
        t('invoices.issued')
      ]
    end
  end

  def invoice_sent_data
    if invoice.sent_at?
      [
        '⬤', # Middle Dot
        l(invoice.sent_at, format: :long),
        t('invoices.sent')
      ]
    end
  end

  def reminder_sent_data(reminder, count)
    [
      '⬤', # Middle Dot
      l(reminder.created_at.to_date, format: :long),
      "#{count}. #{t('invoices.reminder_sent')}"
    ]
  end

  def payment_data(payment)
    [
      '⬤', # Middle Dot
      l(payment.received_at, format: :long),
      "#{number_to_currency(payment.amount)} #{t('invoices.payd')}"
    ]
  end
end
