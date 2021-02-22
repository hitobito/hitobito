# frozen_string_literal: true

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ApplicationMailer < ActionMailer::Base
  HEADERS_TO_SANITIZE = [:to, :cc, :bcc, :from, :sender, :return_path, :reply_to].freeze

  def mail(headers = {}, &block)
    HEADERS_TO_SANITIZE.each do |h|
      if headers.key?(h) && headers[h].present?
        headers[h] = IdnSanitizer.sanitize(headers[h])
      end
    end
    super(headers, &block)
  end

  private

  def compose(recipients, content_key)
    values = values_for_placeholders(content_key)
    custom_content_mail(recipients, content_key, values) if recipients.present?
  end

  # TODO: deprecate/remove values-parameter and call values_for_placeholders instead
  def custom_content_mail(recipients, content_key, values, headers = {})
    content = CustomContent.get(content_key)
    headers[:to] = use_mailing_emails(recipients)
    headers[:subject] ||= content.subject_with_values(values)
    mail(headers) do |format|
      format.html { render plain: content.body_with_values(values) }
    end
  end

  def values_for_placeholders(content_key)
    content = CustomContent.get(content_key)
    content.placeholders_list.index_with do |token|
      send(:"placeholder_#{token.underscore}")
    end
  end

  def use_mailing_emails(recipients)
    if Array(recipients).first.is_a?(Person)
      Person.mailing_emails_for(recipients)
    else
      recipients
    end
  end

  def with_personal_sender(person, headers = {})
    headers[:return_path] = return_path(person)
    headers[:sender] = return_path(person)
    headers[:reply_to] = person.email
    headers
  end

  # use list return path functionality to send a 'no-reply' email with the sender's email
  # as reply-to address
  def return_path(sender)
    MailRelay::Lists.personal_return_path(MailRelay::Lists.app_sender_name, sender.email)
  end

  def link_to(label, url = nil)
    "<a href=\"#{url || label}\">#{label}</a>"
  end
end
