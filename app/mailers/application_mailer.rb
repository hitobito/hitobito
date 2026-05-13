# frozen_string_literal: true

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::OutputSafetyHelper

  HEADERS_TO_SANITIZE = [:to, :cc, :bcc, :from, :sender, :return_path, :reply_to].freeze

  helper :webpack, :utility

  after_deliver :record_system_mail_message

  def mail(headers = {}, &block)
    HEADERS_TO_SANITIZE.each do |h|
      if headers.key?(h) && headers[h].present?
        headers[h] = IdnSanitizer.sanitize(headers[h])
      end
    end
    localize_email_sender(super)
  end

  private

  def compose(recipients, content_key, context: nil)
    values = values_for_placeholders(content_key, context:)
    custom_content_mail(recipients, content_key, values, context:) if recipients.present?
  end

  def custom_content_mail(recipients, content_key, values, headers = {}, context: nil) # rubocop:disable Metrics/AbcSize
    emails = unblocked_emails(recipients)
    return if emails.none? && message.cc.blank? && message.bcc.blank?

    headers[:to] = emails
    content = custom_content(content_key, context:)
    headers[:subject] ||= unescape_html(content.subject_with_values(values))
    @body = content.body_with_values(values)
    mail(headers) do |format|
      format.html { render html: @body, layout: true }
    end
  end

  def values_for_placeholders(content_key, context: nil)
    content = custom_content(content_key, context:)
    content.placeholders_list.index_with do |token|
      send(:"placeholder_#{token.underscore}")
    end
  end

  def custom_content(key, context: nil)
    @custom_contents ||= {}
    @custom_contents[[key, context]] ||= CustomContent.get(key, context:)
  end

  def unblocked_emails(recipients)
    Array(use_mailing_emails(recipients)).reject { |email| Bounce.blocked?(email) }
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

  def record_system_mail_for(recipient)
    @system_mail_recipients ||= []
    # skip event guests (who as person have no id)
    @system_mail_recipients.push(*Array(recipient).select(&:id))
  end

  def record_system_mail_message
    return if @system_mail_recipients.blank?

    record = Message::SystemMail.create!(system_mail_attributes)
    @system_mail_recipients.each do |r|
      record.message_recipients.create!(system_mail_recipient_attributes(r))
    end
  end

  def system_mail_attributes
    {
      raw_source: @body,
      subject: message.subject,
      sent_at: Time.zone.now,
      state: :finished,
      recipient_count: @system_mail_recipients.size,
      event_id: @event&.id || @course&.id
    }
  end

  def system_mail_recipient_attributes(person)
    {
      person:,
      state: :sent,
      email: use_mailing_emails(person).first
    }
  end

  def link_to(label, url = nil)
    # Escape the label and URL to prevent XSS attacks in the link text.
    safe_label = escape_html(label)
    safe_url = url.nil? ? safe_label : escape_html(url)

    # Only escape ampersand in invalid URLs (like mailto links or JavaScript).
    safe_url.gsub!("&amp;", "&") if safe_url.match?(/\Ahttps?:\/\/[\S]+\z/)

    "<a href=\"#{safe_url}\">#{safe_label}</a>".html_safe
  end

  def br_tag = "<br/>".html_safe

  def join_lines(lines, separator = br_tag) = safe_join(lines, separator)

  def convert_newlines_to_breaks(text) = join_lines(text.split("\n"))

  def escape_html(html) = ERB::Util.html_escape(html)

  def unescape_html(html) = CGI.unescapeHTML(html)
end
