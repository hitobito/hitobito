# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
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
    invoice.decorate.format_currency(invoice_list.amount_total)
  end

  def format_invoice_state(invoice)
    type = case invoice.state
    when /draft|cancelled/ then "info"
    when /sent|issued|partial/ then "warning"
    when /payed|excess/ then "success"
    when /reminded/ then "danger"
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

  def format_invoice_last_payment_at(invoice)
    f(invoice.last_payment_at)
  end

  def invoice_state_label(invoice)
    text = invoice.state_label
    text << " (#{invoice.payment_reminders.list.last.title})" if invoice.reminded?
    text
  end

  def invoice_link(invoice)
    case parent
    when Group then group_invoice_path(invoice.group_id, invoice)
    when InvoiceList then group_invoice_list_invoice_path(parent.group, parent, invoice)
    end
  end

  def invoice_due_since_options
    [:one_day, :one_week, :one_month].collect do |key|
      [key, I18n.t("invoices.filter.due_since_list.#{key}")]
    end
  end

  def invoice_button(people: [], mailing_list: nil, filter: nil, group: nil)
    Dropdown::InvoiceNew.new(
      self,
      people: people,
      mailing_list: mailing_list,
      group: group,
      filter: filter
    ).button_or_dropdown
  end

  def invoices_export_dropdown
    Dropdown::Invoices.new(self, params, :download).export
  end

  def invoices_evaluation_export_dropdown
    Dropdown::Invoices::Evaluation.new(self, params, :download).export
  end

  def invoices_print_dropdown
    if parent.is_a?(InvoiceList) && Message::LetterWithInvoice.exists?(invoice_list: parent)
      Dropdown::LetterWithInvoice.new(self, params, :print).print
    else
      Dropdown::Invoices.new(self, params, :print).print
    end
  end

  def invoice_sending_dropdown
    Dropdown::InvoiceSending.new(self, params)
  end

  def invoice_history(invoice)
    Invoice::History.new(self, invoice)
  end

  def invoice_receiver_address(invoice)
    return unless invoice.recipient_address

    name, *address = invoice.recipient_address.split("\n")
    name = link_to(invoice.recipient, invoice.recipient) if name == invoice.recipient&.full_name

    content_tag(:p) do
      safe_join([
        content_tag(:b) { name },
        *address,
        mail_to(invoice.recipient_email)
      ], "<br/>".html_safe)
    end
  end
end
