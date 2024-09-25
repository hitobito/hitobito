# frozen_string_literal: true

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class DeliveryReportMailer < ApplicationMailer
  CONTENT_BULK_MAIL_SUCCESS = "bulk_mail_success"
  CONTENT_BULK_MAIL_WITH_FAILED = "bulk_mail_with_failed"

  def bulk_mail(
    report_to,
    envelope_sender,
    mail_subject,
    total_recipients,
    delivered_at,
    failed_recipients = nil
  )

    content = failed_recipients.present? ? CONTENT_BULK_MAIL_WITH_FAILED : CONTENT_BULK_MAIL_SUCCESS
    @envelope_sender = envelope_sender
    @mail_subject = mail_subject
    @total_recipients = total_recipients
    @delivered_at = delivered_at
    @failed_recipients = failed_recipients
    custom_content_mail(report_to,
      content,
      values_for_placeholders(content))
  end

  private

  def placeholder_mail_to
    @envelope_sender
  end

  def placeholder_mail_subject
    @mail_subject
  end

  def placeholder_delivered_at
    I18n.l(@delivered_at)
  end

  def placeholder_total_recipients
    @total_recipients.to_s
  end

  def placeholder_total_succeeded_recipients
    (@total_recipients - @failed_recipients.count).to_s
  end

  def placeholder_failed_recipients
    separated_failed_recipients = @failed_recipients.collect do |r|
      r.join(" | ")
    end
    join_lines(separated_failed_recipients)
  end
end
