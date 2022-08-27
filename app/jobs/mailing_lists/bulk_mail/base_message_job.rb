# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingLists::BulkMail::BaseMessageJob < BaseJob

  EMAIL_LOCAL_PART_BRACKETS = /^.*<(.+)@.+\..+>$/.freeze
  EMAIL_LOCAL_PART = /^(.+)@.+\..+$/.freeze

  self.parameters = [:message]

  def initialize(message)
    super()
    @message = message
  end

  def perform
    raise 'implement in sub class'
  end

  private

  def no_reply_address
    app_sender = Settings.email.sender
    sender =
      app_sender[EMAIL_LOCAL_PART_BRACKETS, 1] ||
      app_sender[EMAIL_LOCAL_PART, 1] ||
      'noreply'
    "#{sender}@#{app_sender_domain}"
  end

  def app_sender_domain
    Settings.email.list_domain || 'localhost'
  end

  def source_mail
    Mail.new(@message.raw_source)
  end

  def list_address
    @message.mailing_list.mail_address
  end
end
