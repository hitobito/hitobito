# frozen_string_literal: true

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::OutputSafetyHelper

  HEADERS_TO_SANITIZE = [:to, :cc, :bcc, :from, :sender, :return_path, :reply_to].freeze

  helper :webpack

  def mail(headers = {}, &block)
    HEADERS_TO_SANITIZE.each do |h|
      if headers.key?(h) && headers[h].present?
        headers[h] = IdnSanitizer.sanitize(headers[h])
      end
    end
    localize_email_sender(super)
  end

  private

  def compose(recipients, content_key)
    values = values_for_placeholders(content_key)
    custom_content_mail(recipients, content_key, values) if recipients.present?
  end

  def custom_content_mail(recipients, content_key, values, headers = {})
    content = CustomContent.get(content_key)
    headers[:to] = use_mailing_emails(recipients)
    headers[:subject] ||= unescape_html(content.subject_with_values(values))
    mail(headers) do |format|
      format.html { render html: content.body_with_values(values), layout: true }
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

  # Overwrite the non localized sender with the localized sender
  def localize_email_sender(message)
    if message[:from].value == Settings.email.sender
      message.from = Hitobito.localized_email_sender
    end
    message
  end

  def with_personal_sender(person, headers = {})
    headers[:return_path] ||= return_path(person)
    headers[:sender] ||= return_path(person)
    headers[:reply_to] ||= person.email
    headers
  end

  # use list return path functionality to send a 'no-reply' email with the sender's email
  # as reply-to address
  def return_path(sender)
    MailRelay::Lists.personal_return_path(MailRelay::Lists.app_sender_name, sender.email)
  end

  def link_to(label, url = nil)
    # Escape the label to prevent XSS attacks in the link text.
    safe_label = escape_html(label)

    # Only escape invalid URLs (like mailto links or JavaScript).
    url ||= label
    safe_url = url.match?(/\Ahttps?:\/\/[\S]+\z/) ? url : escape_html(url)
    "<a href=\"#{safe_url}\">#{safe_label}</a>".html_safe
  end

  def br_tag = "<br/>".html_safe

  def join_lines(lines, separator = br_tag) = safe_join(lines, separator)

  def convert_newlines_to_breaks(text) = join_lines(text.split("\n"))

  def escape_html(html) = ERB::Util.html_escape(html)

  def unescape_html(html) = CGI.unescapeHTML(html)
end
