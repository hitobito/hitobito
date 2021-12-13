# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingLists::BulkMail::SenderRejectedMessageJob < BaseJob

  self.parameters = [:message]

  def initialize(message)
    super()
    @message = message
  end

  def perform
    list_address = @message.mailing_list.mail_address
    reply = create_reply(list_address)
    send(reply)
  end

  private

  def send(mail)
    if defined?(ActionMailer::Base)
      ActionMailer::Base.wrap_delivery_behavior(mail)
    end

    # set Return-Path as recommended in: https://stackoverflow.com/a/154794
    mail.header['Return-Path'] = '<>'
    mail.deliver
  end

  def create_reply(list_address)
    sender = app_sender_email

    source_mail.reply do
      body "Du bist leider nicht berechtigt auf die Liste #{list_address} zu schreiben."
      from sender
    end
  end

  def app_sender_email
    app_sender = Settings.email.sender
    sender = app_sender[/^.*<(.+)@.+\..+>$/, 1] || app_sender[/^(.+)@.+\..+$/, 1] || 'noreply'
    "#{sender}@#{app_sender_domain}"
  end

  def app_sender_domain
    Settings.email.list_domain || 'localhost'
  end

  def source_mail
    Mail.new(@message.raw_source)
  end
end
