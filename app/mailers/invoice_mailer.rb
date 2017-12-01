# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceMailer < ApplicationMailer

  CONTENT_INVOICE_NOTIFICATION = 'content_invoice_notification'.freeze

  def notification(recipient_name, recipient_mail, sender, invoice, invoice_file)
    @recipient_name = recipient_name
    @recipient_mail = recipient_mail
    @sender         = sender
    @invoice        = invoice

    attachments[invoice.filename] = invoice_file

    custom_content_mail(@recipient_mail, CONTENT_INVOICE_NOTIFICATION,
                        values_for_placeholders(CONTENT_INVOICE_NOTIFICATION),
                        with_personal_sender(@sender))
  end

  private

  def placeholder_recipient_name
    @recipient_name
  end

  def placeholder_invoice_number
    @invoice.sequence_number
  end

  def placeholder_invoice_items
    @invoice.invoice_items.map do |item|
      [
        item.name,
        item.description,
        item.total
      ].join('<br/>')
    end.join('<br/>' * 2)
  end

  def placeholder_invoice_total
    calculated = @invoice.calculated

    content_tag :table do
      [:total, :vat].map do |key|
        content_tag :tr do
          [content_tag(:th, t("activerecord.attributes.invoice.#{key}")),
           content_tag(:td, calculated[key])].join
        end
      end.join
    end
  end

  def placeholder_group_name
    @sender.primary_group.name
  end

  def placeholder_payment_information
    @invoice.invoice_config.payment_information
  end

  def content_tag(name, content = nil)
    content = yield if block_given?
    "<#{name}>#{content}</#{name}>"
  end

end
