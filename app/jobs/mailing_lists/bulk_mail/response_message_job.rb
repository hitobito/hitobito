# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingLists::BulkMail::ResponseMessageJob < BaseJob

  self.parameters = [:mail, :reason]

  def initialize(message, reason)
    super()
    @message = message
    @reason = reason
  end

  def perform
    case @reason
    when :sender_rejected
      send_sender_notification
    else
      # type code here
    end
  end

  def send_sender_notification
    sender = app_sender_email
    list_address = mailing_list_address
    not_allowed_reply(sender, list_address)
  end

  def not_allowed_reply(sender, list_address)
    mail.reply do
      body "Du bist nicht berechtigt, auf die Liste #{list_address} zu schreiben."
      from sender
    end
  end

  def app_sender_email
    app_sender = Settings.email.sender
    app_sender[/^.*<(.+)@.+\..+>$/, 1] || app_sender[/^(.+)@.+\..+$/, 1] || 'noreply'
  end

  def mailing_list_address
    binding.pry
  end

  def send_message
    if defined?(ActionMailer::Base)
      ActionMailer::Base.wrap_delivery_behavior(message)
    end

    mail.header['Precedence'] = 'list'
    mail.header['List-Id'] = list_id
    mail.deliver
  end

  def mail_domain
    Settings.email.list_domain
  end

end
