# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoicesHelper
  def format_invoice_run_amount_paid(invoice_run)
    invoice = invoice_run.invoice || invoice_run.group.issued_invoices.build
    invoice.decorate.format_currency(invoice_run.amount_paid)
  end

  def format_invoice_run_amount_total(invoice_run)
    invoice = invoice_run.invoice || invoice_run.group.issued_invoices.build
    invoice.decorate.format_currency(invoice_run.amount_total)
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
    elsif invoice.recipient_company_name.present?
      invoice.recipient_company_name
    elsif invoice.recipient_name.present?
      invoice.recipient_name
    elsif invoice.deprecated_recipient_address.present?
      invoice.deprecated_recipient_address.split("\n").first
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
    when InvoiceRun then group_invoice_run_invoice_path(parent.group, parent, invoice)
    end
  end

  def invoice_due_since_options
    [:one_day, :one_week, :one_month].collect do |key|
      [key, I18n.t("invoices.filter.due_since_list.#{key}")]
    end
  end

  def invoice_button(people: [], mailing_list: nil, filter: nil, group: nil, event: nil)
    Dropdown::InvoiceNew.new(
      self,
      people: people,
      mailing_list: mailing_list,
      group: group,
      event: event,
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
    if parent.is_a?(InvoiceRun) && Message::LetterWithInvoice.exists?(invoice_run: parent)
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
    return if invoice.recipient_address_values.empty? && invoice.deprecated_recipient_address.blank?

    first_line, *other_lines = if invoice.recipient_address_values.empty?
      # Old invoices do not have recipient_address_values, therefore we have to use the old address
      invoice.deprecated_recipient_address&.split("\n") || []
    else
      invoice.recipient_address_values
    end

    content_tag(:p) do
      safe_join([
        content_tag(:b) { first_line },
        *other_lines,
        mail_to(invoice.recipient_email)
      ], "<br/>".html_safe)
    end
  end

  def invoice_payee_address(invoice)
    invoice.payee_address_values.join(", ")
  end
end
