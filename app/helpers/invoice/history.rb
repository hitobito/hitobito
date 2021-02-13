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
        invoice_history_entry(invoice_issued_data, "blue"),
        invoice_history_entry(invoice_sent_data, "blue"),
      ]

      table_rows << invoice_reminder_rows
      table_rows << invoice_payment_rows
      table_rows.compact.join.html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  private

  def invoice_reminder_rows
    invoice.payment_reminders.list.collect.with_index do |reminder, count|
      invoice_history_entry(reminder_sent_data(reminder, count + 1), "red")
    end
  end

  def invoice_payment_rows
    invoice.payments.list.collect do |payment|
      invoice_history_entry(payment_data(payment), "green")
    end
  end

  def invoice_history_entry(data, color)
    return unless data
    content_tag :tr do
      data.collect { |d|
        concat content_tag(:td, d, class: color)
      }.to_s.html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  def invoice_issued_data
    if invoice.issued_at?
      [
        "⬤", # Middle Dot
        long_date(invoice.issued_at),
        t("invoices.issued"),
      ]
    end
  end

  def invoice_sent_data
    if invoice.sent_at?
      [
        "⬤", # Middle Dot
        long_date(invoice.sent_at),
        t("invoices.sent"),
      ]
    end
  end

  def reminder_sent_data(reminder, count)
    [
      "⬤", # Middle Dot
      long_date(reminder.created_at.to_date),
      "#{count}. #{t("invoices.reminder_sent",
        title: reminder.title,
        date: long_date(reminder.due_at))}",
    ]
  end

  def payment_data(payment)
    [
      "⬤", # Middle Dot
      long_date(payment.received_at),
      "#{invoice.decorate.format_currency(payment.amount)} #{t("invoices.payed")}",
    ]
  end

  def long_date(date)
    l(date, format: :long)
  end
end
