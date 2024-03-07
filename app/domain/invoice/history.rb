# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::History
  attr_reader :template, :invoice

  delegate :content_tag, :t, :concat, to: :template

  def initialize(template, invoice)
    @template = template
    @invoice = invoice
  end

  def to_s
    content_tag :table do
      invoice_history_entries
        .sort
        .map { |entry| entry.to_html(template) }
        .join
        .html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  private

  def invoice_history_entries
    [
      invoice_issued_entry,
      invoice_sent_entry,
      *reminder_sent_entries,
      *payment_entries
    ].select(&:valid?)
  end

  def reminder_sent_entries
    invoice.payment_reminders.list.map.with_index do |reminder, count|
      reminder_sent_entry(reminder, count + 1)
    end
  end

  def payment_entries
    invoice.payments.list.map { |payment| payment_data(payment) }
  end

  class HistoryEntryData
    attr_reader :date

    def initialize(date, event, color)
      @date = date
      @event = event
      @color = color
    end

    def valid?
      @date.present?
    end

    def <=>(other)
      @date <=> other.date
    end

    def data_row
      ['⬤', I18n.l(date, format: :long), @event]
    end

    def to_html(template)
      return '' unless valid?

      template.content_tag :tr do
        data_row.map do |d|
          template.concat template.content_tag(:td, d, class: @color)
        end.to_s.html_safe # rubocop:disable Rails/OutputSafety
      end
    end
  end

  def invoice_issued_entry
    HistoryEntryData.new(invoice.issued_at, t('invoices.issued'), 'blue')
  end

  def invoice_sent_entry
    HistoryEntryData.new(invoice.sent_at, t('invoices.sent'), 'blue')
  end

  def reminder_sent_entry(reminder, count)
    message = "#{count}. #{t('invoices.reminder_sent',
                             title: reminder.title,
                             date: template.l(reminder.due_at, format: :long))}"

    HistoryEntryData.new(reminder.created_at.to_date, message, 'red')
  end

  def payment_data(payment)
    message = "#{invoice.decorate.format_currency(payment.amount)} #{t('invoices.payed')}"

    HistoryEntryData.new(payment.received_at, message, 'green')
  end
end
