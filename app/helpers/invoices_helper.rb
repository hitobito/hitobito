# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoicesHelper

  def format_invoice_list_amount_paid(invoice_list)
    invoice = invoice_list.invoice || invoice_list.group.invoices.build
    invoice.decorate.format_currency(invoice_list.amount_paid)
  end

  def format_invoice_list_amount_total(invoice_list)
    invoice = invoice_list.invoice || invoice_list.group.invoices.build
    invoice.decorate.format_currency(invoice_list.amount_total) if invoice
  end

  def format_invoice_state(invoice)
    type = case invoice.state
           when /draft|cancelled/ then 'info'
           when /sent|issued/ then 'warning'
           when /payed/ then 'success'
           when /reminded/ then 'important'
           end
    badge(invoice_state_label(invoice), type)
  end

  def format_invoice_recipient(invoice)
    if invoice.recipient
      link_to(invoice.recipient, invoice.recipient)
    else
      invoice.recipient_address.split("\n").first
    end
  end

  def invoice_state_label(invoice)
    text = invoice.state_label
    text << " (#{invoice.payment_reminders.list.last.title})" if invoice.reminded?
    text
  end

  def invoice_due_since_options
    [:one_day, :one_week, :one_month].collect do |key|
      [key, I18n.t("invoices.filter.due_since_list.#{key}")]
    end
  end

  def invoice_button(people: [], mailing_list: nil, filter: nil)
    Dropdown::InvoiceNew.new(self, {
      people: people,
      mailing_list: mailing_list,
      filter: filter
    }).button_or_dropdown
  end

  def invoices_export_dropdown
    Dropdown::Invoices.new(self, params, :download).export
  end

  def invoices_print_dropdown
    Dropdown::Invoices.new(self, params, :print).print
  end

  def invoice_sending_dropdown
    Dropdown::InvoiceSending.new(self, params)
  end

  def invoice_history(invoice)
    Invoice::History.new(self, invoice)
  end

  def invoice_receiver_address(invoice)
    return unless invoice.recipient_address
    out = ''
    recipient_address_lines = invoice.recipient_address.split(/\n/)
    content_tag(:p) do
      recipient_address_lines.collect do |l|
        out << (l == recipient_address_lines.first ? "<b>#{l}</b>" : l) + '<br>'
      end
      out << mail_to(entry.recipient_email)
      out.html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
