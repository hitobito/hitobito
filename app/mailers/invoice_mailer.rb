# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceMailer < ApplicationMailer
  CONTENT_INVOICE_NOTIFICATION = "content_invoice_notification"

  def mail(headers = {}, &block)
    mail = super

    if @invoice.invoice_config.sender_name.present?
      mail.from = "#{@invoice.invoice_config.sender_name} <#{mail.from[0]}>"
    end
  end

  def notification(invoice, sender)
    @sender = sender
    @invoice = invoice

    attachments[invoice.filename] = generate_pdf

    custom_content_mail(@invoice.recipient_email, CONTENT_INVOICE_NOTIFICATION,
      values_for_placeholders(CONTENT_INVOICE_NOTIFICATION),
      mail_headers(@sender, @invoice.invoice_config.email),
      context: @invoice.invoice_config)
  end

  private

  def generate_pdf
    Export::Pdf::Invoice.render(@invoice, pdf_options)
  end

  def placeholder_recipient_name
    @invoice.recipient_name || @invoice.recipient_email
  end

  def placeholder_invoice_number
    @invoice.sequence_number
  end

  def placeholder_invoice_items
    join_lines(InvoiceItemDecorator.decorate_collection(@invoice.invoice_items).map do |item|
      join_lines([
        item.name,
        item.description,
        item.total
      ])
    end, "<br/>".html_safe * 2)
  end

  def placeholder_invoice_total
    content_tag :table do
      join_lines([:total, :vat].map do |key|
        content_tag :tr do
          join_lines([content_tag(:th, t("activerecord.attributes.invoice.#{key}")),
            content_tag(:td, @invoice.decorate.send(key))])
        end
      end)
    end
  end

  def placeholder_group_address
    [group.name,
      group.address,
      [group.zip_code, group.town].compact.join(" ").presence].compact.join(", ")
  end

  def placeholder_group_name
    group.name
  end

  def placeholder_payment_information
    @invoice.invoice_config.payment_information.to_s
  end

  def content_tag(name, content = nil)
    content = yield if block_given?
    "<#{name}>".html_safe + content + "</#{name}>".html_safe
  end

  def group
    @invoice.group
  end

  def pdf_options
    {articles: true, payment_slip: true}
  end

  def mail_headers(person, email)
    sender = email.blank? ? person : Person.new(email: email)
    with_personal_sender(sender)
  end
end
