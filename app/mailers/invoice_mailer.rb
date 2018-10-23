# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceMailer < ApplicationMailer

  CONTENT_INVOICE_NOTIFICATION = 'content_invoice_notification'.freeze

  def notification(invoice, sender)
    @sender  = sender
    @invoice = invoice

    attachments[invoice.filename] = generate_pdf

    custom_content_mail(@invoice.recipient_email, CONTENT_INVOICE_NOTIFICATION,
                        values_for_placeholders(CONTENT_INVOICE_NOTIFICATION),
                        mail_headers(@sender, @invoice.invoice_config.email))
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
    InvoiceItemDecorator.decorate_collection(@invoice.invoice_items).map do |item|
      [
        item.name,
        item.description,
        item.total
      ].join('<br/>')
    end.join('<br/>' * 2)
  end

  def placeholder_invoice_total
    content_tag :table do
      [:total, :vat].map do |key|
        content_tag :tr do
          [content_tag(:th, t("activerecord.attributes.invoice.#{key}")),
           content_tag(:td, @invoice.decorate.send(key))].join
        end
      end.join
    end
  end

  def placeholder_group_address
    [group.name,
     group.address,
     [group.zip_code, group.town].compact.join(' ').presence].compact.join(', ')
  end

  def placeholder_group_name
    group.name
  end

  def placeholder_payment_information
    @invoice.invoice_config.payment_information.to_s
  end

  def content_tag(name, content = nil)
    content = yield if block_given?
    "<#{name}>#{content}</#{name}>"
  end

  def group
    @invoice.group
  end

  def pdf_options
    { articles: true, payment_slip: true }
  end

  def mail_headers(person, email)
    return with_personal_sender(person) if email.blank?
    { return_path: email, sender: email, reply_to: email, from: email }
  end

end
