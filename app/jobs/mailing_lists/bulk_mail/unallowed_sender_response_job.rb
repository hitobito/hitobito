# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingLists::BulkMail::UnallowedSenderResponseJob < BaseJob

  self.parameters = [:message]

  def initialize(message)
    super()
    @message = message
  end

  def perform
    sender = app_sender_email
    list_address = @message.mailing_list.mail_address
    reply = not_allowed_reply(sender, list_address)
    send_response(reply)
  end

  private

  def send_response(mail)
    if defined?(ActionMailer::Base)
      ActionMailer::Base.wrap_delivery_behavior(mail)
    end

    # set Return-Path as recommended in: https://stackoverflow.com/a/154794
    mail.header['Return-Path'] = '<>'
    mail.deliver
  end

  def not_allowed_reply(sender, list_address)
    source_mail.reply do
      body "Du bist nicht berechtigt, auf die Liste #{list_address} zu schreiben."
      from sender
    end
  end

  def app_sender_email
    app_sender = Settings.email.sender
    app_sender[/^.*<(.+)@.+\..+>$/, 1] || app_sender[/^(.+)@.+\..+$/, 1] || 'noreply'
  end

  def source_mail
    Mail.new(@message.raw_source)
  end
end
