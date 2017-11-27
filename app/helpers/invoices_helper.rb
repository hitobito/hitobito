# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoicesHelper

  def format_invoice_state(invoice)
    type = case invoice.state
           when /draft|cancelled/ then 'info'
           when /sent/ then 'warning'
           when /payed/ then 'success'
           when /overdue|reminded/ then 'important'
           end
    badge(invoice.state_label, type)
  end

  def invoices_dropdown
    Dropdown::InvoicesExport.new(self, params).to_s
  end

  def invoice_receiver_address(invoice)
    return unless invoice.recipient_address
    out = ''
    recipient_address_lines = invoice.recipient_address.split(/\n/)
    content_tag(:p) do
      recipient_address_lines.collect do |l|
        out << (l == recipient_address_lines.first ? "<b>#{l}</b>" : l) + '<br>'
      end
      out << mail_to(entry.recipient.email)
      out.html_safe
    end
  end

  def invoice_history(invoice)
    return unless invoice.sent?

    content_tag :table do
      table_rows = [history_entry(invoice_sent_data(invoice), 'blue')]
      table_rows << invoice_reminder_rows(invoice)
      # TODO: Payment done
      table_rows.join.html_safe
    end
  end

  private

  def invoice_reminder_rows(invoice)
    if invoice.reminder_sent?
      invoice.payment_reminders.collect.with_index do |reminder, count|
        next unless reminder.persisted?
        history_entry(reminder_sent_data(reminder, count + 1), 'red')
      end
    end
  end

  def history_entry(data, color)
    content_tag :tr do
      data.collect do |d|
        concat content_tag(:td, d, class: color)
      end.to_s.html_safe
    end
  end

  def invoice_sent_data(invoice)
    [
      '⬤', # Middle Dot
      l(invoice.sent_at, format: :long),
      t('invoices.sent')
    ]
  end

  def reminder_sent_data(reminder, count)
    [
      '⬤', # Middle Dot
      l(reminder.created_at.to_date, format: :long),
      "#{count}. #{t('invoices.reminder_sent')}"
    ]
  end
end
